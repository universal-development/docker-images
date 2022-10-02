def choiceArray = []
node {
    checkout scm
    def folders = sh(returnStdout: true, script: "ls $WORKSPACE")

    folders.split().each {
        choiceArray << it
    }
}

pipeline {
    agent { node { label 'wrench' } }
    parameters {
        parameters { choice(name: 'image', choices: choiceArray, description: 'Select image to build') }
    }
    options {
      buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
      disableConcurrentBuilds()
    }

    stages {
        stage('Checkout'){
            steps{
                checkout scm: [
                        $class: 'GitSCM',
                        branches: scm.branches,
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [[$class: 'SubmoduleOption',
                                      disableSubmodules: false,
                                      parentCredentials: false,
                                      recursiveSubmodules: true,
                                      reference: '',
                                      trackingSubmodules: false]],
                        submoduleCfg: [],
                        userRemoteConfigs: scm.userRemoteConfigs
                ]
            }
        }

        stage('Build') {
           steps {
             sh 'make build image=${params.image}'
           }
        }

        stage('Publish') {
           when {
               expression {
                   return params.PublishImage == true
               }
           }
           steps {
             sh 'make push image=${params.image}'
           }
        }

    }
}
