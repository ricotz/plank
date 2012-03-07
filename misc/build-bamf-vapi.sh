#!/bin/sh

vala-gen-introspect libbamf bamf
cd bamf && vapigen --library bamf --metadatadir . --directory ../../vapi libbamf.gi
