# Base image
FROM python:3.7-alpine

# When you clean up the apk cache by removing /var/cache/apk/ it reduces the
# image size, since the apk cache is not stored in a layer.

RUN apk add --update \
    ##### SYSTEM PACKAGES ##########
    build-base \
    gcc \
    patch \
    make \
    musl-dev \
    python3-dev \
    libffi-dev \
    gfortran \
    ##### OPENBABEL ###############
    cmake \
    cairo \
    cairo-dev \
    eigen-dev \
    libxml2-dev \
    ##### OPENBABEL (PYTHON WRAPPER)#
    swig \
    ##### NUMPY ##################
    lapack \
    lapack-dev \
    openblas \
    #############################
    && rm -rf /var/cache/apk/*

# Install python requirements
RUN pip install --upgrade pip

WORKDIR /tmp 

# Install Open Babel
RUN wget https://ufpr.dl.sourceforge.net/project/openbabel/openbabel/2.4.1/openbabel-2.4.1.tar.gz \
    && tar zxvf openbabel-2.4.1.tar.gz \
    && mv openbabel-2.4.1/ ob-src \
    && mkdir ob-build \
    && mkdir /openbabel

RUN cd ob-src/ \
   && cmake ../ob-src -DPYTHON_BINDINGS=ON -DRUN_SWIG=ON -DCMAKE_INSTALL_PREFIX=/openbabel 2>&1 | tee cmake.out \
   && make 2>&1 | tee make.out

RUN cd ob-src/ \
   && make install \
   && export PATH="$PATH:/openbabel/bin" \
   && export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/openbabel/lib" \
   && cd /tmp && rm -rf *

ENV PYTHONPATH="/openbabel/lib/python3.7/site-packages/"

# FIX bug: openbabel importing
# https://github.com/hseara/openbabel/commit/92f4646d5cbf8d3291c66f9bff7ae61b6d535763
COPY openbabel.py.patch /openbabel/lib/python3.7/site-packages/
RUN cd /openbabel/lib/python3.7/site-packages/ \
   && patch < openbabel.py.patch && rm openbabel.py.patch
