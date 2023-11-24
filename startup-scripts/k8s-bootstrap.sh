#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -e

#
STEP_CNT=4

echo_step() {
cat <<EOF
######################################################################
Init Step ${1}/${STEP_CNT} [${2}] -- ${3}
######################################################################
EOF
}

: "${ADMIN_PASSWORD:=admin}"
: "${SUPERSET_LOAD_EXAMPLES:=true}"
: "${CHARM_FUNCTION:=app-gunicorn}"

# If Cypress run – overwrite the password for admin and export env variables
if [ "$CYPRESS_CONFIG" == "true" ]; then
    ADMIN_PASSWORD="general"
    export SUPERSET_CONFIG=tests.integration_tests.superset_test_config
    export SUPERSET_TESTENV=true
    export SUPERSET__SQLALCHEMY_DATABASE_URI=postgresql+psycopg2://superset:superset@db:5432/superset
fi
# Initialize the database
echo_step "1" "Starting" "Applying DB migrations"
cd /app && superset db upgrade
echo_step "1" "Complete" "Applying DB migrations"

# Create an admin user
echo_step "2" "Starting" "Setting up admin user ( admin / ${ADMIN_PASSWORD} )"
superset fab create-admin \
              --username admin \
              --firstname Superset \
              --lastname Admin \
              --email admin@superset.com \
              --password "$ADMIN_PASSWORD"
echo_step "2" "Complete" "Setting up admin user"
# Create default roles and permissions
echo_step "3" "Starting" "Setting up roles and perms"
superset init
echo_step "3" "Complete" "Setting up roles and perms"

if [ "$SUPERSET_LOAD_EXAMPLES" = true ]; then
    # Load some data to play with
    echo_step "4" "Starting" "Loading examples"
    # If Cypress run which consumes superset_test_config – load required data for tests
    if [ "$CYPRESS_CONFIG" == "true" ]; then
        superset load_test_users
        superset load_examples --load-test-data
    else
        superset load_examples
    fi
    echo_step "4" "Complete" "Loading examples"
fi


if [[ "${CHARM_FUNCTION}" == "worker" ]]; then
  echo "Starting Celery worker..."
  celery --app=superset.tasks.celery_app:app worker -O fair -l INFO --uid 1
elif [[ "${CHARM_FUNCTION}" == "beat" ]]; then
  echo "Starting Celery beat..."
  celery --app=superset.tasks.celery_app:app beat --pidfile /tmp/celerybeat.pid -l INFO -s "${SUPERSET_HOME}"/celerybeat-schedule
elif [[ "${CHARM_FUNCTION}" == "app" ]]; then
  echo "Starting web app..."
  flask run -p 8088 --with-threads --reload --debugger --host=0.0.0.0
elif [[ "${CHARM_FUNCTION}" == "app-gunicorn" ]]; then
  echo "Starting web app..."
  /app/k8s/run-server.sh
fi
