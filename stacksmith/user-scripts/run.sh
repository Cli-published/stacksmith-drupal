#!/bin/bash

echo "==> Starting Apache..."
set +u && . /opt/rh/httpd24/enable && set -u
httpd -DFOREGROUND
