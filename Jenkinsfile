// pipeline tools require python3 env with jinja2, pytest and pyyaml installed

pipeline {
    agent any
    environment {
        compose_cfg='docker-compose.yaml'
        compose_f_opt=''
        container='simpleconsent'
        d_containers="${container} dsimpleconsent_simpleconsent_1"
        d_app_volumes='simpleconsent.opt_etc simpleconsent.settings simpleconsent.var_log'
        service='simpleconsent'
        project='jenkins'
        projopt="-p $project"
        // redundant from docker-compose (circumvent docker-compose issued with `docker exec`):
        image='r2h2/simpleconsent'
        // BASH_TRACE=1
    }
    options { disableConcurrentBuilds() }
    parameters {
        string(defaultValue: 'True', description: '"True": initial cleanup: remove container and volumes; otherwise leave empty', name: 'start_clean')
        string(defaultValue: '', description: '"True": "Set --nocache for docker build; otherwise leave empty', name: 'nocache')
        string(defaultValue: '', description: '"True": push docker image after build; otherwise leave empty', name: 'pushimage')
        string(defaultValue: '', description: '"True": keep running after test; otherwise leave empty to delete container and volumes', name: 'keep_running')
        string(defaultValue: '', description: 'Proxy to use during build', name: 'proxy')
    }

    stages {
        stage('Config ') {
            steps {
                sh '''#!/bin/bash -e
                    echo "using ${compose_cfg} as docker-compose config file"
                    if [[ "$DOCKER_REGISTRY_USER" ]]; then
                        echo "  Docker registry user: $DOCKER_REGISTRY_USER"
                        ./dcshell/update_config.sh "${compose_cfg}.default" $compose_cfg
                    else
                        cp "${compose_cfg}.default" $compose_cfg
                    fi
                    cp -n config.env.default config.env
                    cp -n secrets.env.default secrets.env
                    grep ' image:' $compose_cfg || echo "missing key 'service.image' in ${compose_cfg}"
                    grep ' container_name:' $compose_cfg || echo "missing key 'service.container_name' in ${compose_cfg}"
                '''
            }
        }
        stage('Cleanup ') {
            when {
                expression { params.$start_clean?.trim() != '' }
            }
            steps {
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    remove_containers $d_containers && echo '.'
                    remove_volumes $d_app_volumes && echo '.'
                    cp -f config.env.default config.env
                    cp -f secrets.env.default secrets.env
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''#!/bin/bash -e
                    source ./jenkins_scripts.sh
                    remove_container_if_not_running $container
                    if [[ "$nocache" ]]; then
                         nocacheopt='-c'
                         echo 'build with option nocache'
                    fi
                    if [[ "${proxy]" ]]; then
                        echo "setting proxy: ${proxy}"
                        export http_proxy=${proxy}
                        export https_proxy=${proxy}
                    fi
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build $compose_f_opt $nocacheopt || \
                        (rc=$?; echo "build failed with rc ${rc}"; exit $rc)
                '''
            }
        }
        stage('Push ') {
            when {
                expression { params.pushimage?.trim() != '' }
            }
            steps {
                sh '''#!/bin/bash -e
                    default_registry=$(docker info 2> /dev/null |egrep '^Registry' | awk '{print $2}')
                    echo "  Docker default registry: $default_registry"
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build $compose_f_opt -P
                '''
            }
        }
    }
    post {
        always {
            sh '''#!/bin/bash -e
                if [[ "$keep_running" ]]; then
                    echo "Keep container running"
                else
                    echo 'Cleanup: container, volumes'
                    source ./jenkins_scripts.sh
                    exec_compose "rm --force -v" || true
                fi
            '''
        }
    }
}