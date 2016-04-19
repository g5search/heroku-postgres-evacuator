#!/bin/bash
./validate_general_vars && ./validate_aws_vars.sh && ./prep_creds.rb && ./rollback.rb
