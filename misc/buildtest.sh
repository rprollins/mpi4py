#!/bin/sh

PYTHON=python
MPIIMP=mpich2

for arg in "$@" ; do
    case "$arg" in
    -q)
    QUIET=-q
    shift
    ;;
    --py=*)
    PYTHON=python`echo A$arg | sed -e 's/A--py=//g'`
    shift
    ;;
    --mpi=*)
    MPIIMP=`echo A$arg | sed -e 's/A--mpi=//g'`
    shift
    ;;
    esac
done

echo ---------------------
echo Python ---- $PYTHON
echo MPI ------- $MPIIMP
echo ---------------------

NAME=`$PYTHON setup.py -v --name`
VERSION=`$PYTHON setup.py -v --version`

BUILDDIR=/tmp/$NAME-buildtest
$PYTHON setup.py $QUIET sdist
rm -rf $BUILDDIR && mkdir -p $BUILDDIR
cp dist/$NAME-$VERSION.tar.gz $BUILDDIR

if [ -f misc/env-$MPIIMP.sh ]; then
    source misc/env-$MPIIMP.sh
fi
cd $BUILDDIR
tar -zxf $NAME-$VERSION.tar.gz
cd $NAME-$VERSION
$PYTHON setup.py $QUIET install --home=$BUILDDIR
MPI4PYPATH=$BUILDDIR/lib64/python:$BUILDDIR/lib/python
$MPISTARTUP
$PYTHON test/runtests.py $QUIET --path=$MPI4PYPATH $@ < /dev/null
sleep 3
rm -rf $BUILDDIR
$MPISHUTDOWN
