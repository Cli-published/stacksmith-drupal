#!/bin/bash

echo "==> Starting Apache"
scl enable httpd24 'httpd -DFOREGROUND'
