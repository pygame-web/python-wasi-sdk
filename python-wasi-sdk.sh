#!/bin/bash
reset

# TODO: check how dbg tools work with default settings
# https://developer.chrome.com/blog/wasm-debugging-2020/


. /etc/lsb-release
DISTRIB="${DISTRIB_ID}-${DISTRIB_RELEASE}"

export SDKROOT=/opt/python-wasm-sdk

export CIVER=${CIVER:-$DISTRIB}
export CI=true

emsdk=false
wasisdk=true


sudo mkdir -p ${SDKROOT}
sudo chmod 777 ${SDKROOT}

ORIGIN=$(pwd)

# 3.12 3.11 3.10

BUILDS=${BUILDS:-3.12 3.11}

for PYBUILD in $BUILDS
do
    cd "$ORIGIN"

    if [ -f ${SDKROOT}/dev ]
    then
        echo -n
    else
        rm -rf ${SDKROOT}/*
    fi

    cp -Rf * ${SDKROOT}/

    if cd ${SDKROOT}/
    then
        mkdir -p build/pycache
        export PYTHONDONTWRITEBYTECODE=1

        # make install cpython will force bytecode generation
        export PYTHONPYCACHEPREFIX="$(realpath build/pycache)"

        . ${CONFIG:-config}

        cd ${SDKROOT}
        . scripts/cpython-fetch.sh

        cd ${SDKROOT}
        . support/__EMSCRIPTEN__.sh

        . scripts/cpython-build-host.sh 2>&1 >/dev/null

        . scripts/cpython-build-host-deps.sh >/dev/null


        cd ${SDKROOT}

        if $wasisdk
        then
            echo WASI SDK TODO
            > ${SDKROOT}/python3-wasi
            > ${SDKROOT}/wasm32-wasi-shell.sh

            chmod +x ${SDKROOT}/python3-wasi ${SDKROOT}/wasm32-wasi-shell.sh

            mkdir -p src build ${SDKROOT}/devices/wasi ${SDKROOT}/prebuilt/wasisdk

        fi

        if $emsdk
        then
            # use ./ or emsdk will pollute env
            ./scripts/emsdk-fetch.sh

            echo " ------------ building cpython wasm ${PYBUILD} ${CIVER} ----------------" 1>&2

            if ./scripts/cpython-build-emsdk.sh > /dev/null
            then
                echo " ---------- building cpython wasm plus ${PYBUILD} ${CIVER} -----------" 1>&2
                if ./scripts/cpython-build-emsdk-deps.sh > /dev/null
                then

                    echo " --------- adding some usefull pkg ${PYBUILD} ${CIVER} ---------" 1>&2
                    ./scripts/cpython-build-emsdk-prebuilt.sh


                    echo "

                    ==========================================================
                                        stripping emsdk ${PYBUILD} ${CIVER}
                    ==========================================================
            " 1>&2
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports*
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports/sdl2/SDL-*
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/cache/ports-builds
                    rm -rf ${SDKROOT}/emsdk/upstream/emscripten/tests

                else
                    echo " cpython-build-emsdk-deps failed" 1>&2
                    exit 101
                fi
            else
                echo " cpython-build-emsdk failed" 1>&2
                exit 105
            fi

        fi

        echo "making tarball" 1>&2

        cd /
        mkdir -p /tmp/sdk
        tar -cpPR \
            ${SDKROOT}/config \
            ${SDKROOT}/python3-was? \
            ${SDKROOT}/wasm32-*-shell.sh \
            ${SDKROOT}/*sdk \
            ${SDKROOT}/devices/* \
            ${SDKROOT}/prebuilt/* \
             > /tmp/sdk/python${PYBUILD}-wasm-sdk-${CIVER}.tar
            lz4 -c --favor-decSpeed --best /tmp/sdk/python${PYBUILD}-wasm-sdk-${CIVER}.tar \
             > /tmp/sdk/python${PYBUILD}-wasm-sdk-${CIVER}.tar.lz4


        echo "done"  1>&2

    else
        echo "cd failed"  1>&2
        exit 124
    fi
done

exit 0

