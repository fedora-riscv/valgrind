# Makefile for source rpm: valgrind
# $Id$
NAME := valgrind
SPECFILE = $(firstword $(wildcard *.spec))

include ../common/Makefile.common
