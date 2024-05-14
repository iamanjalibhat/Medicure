pipeline {
    agent any
	tools{
	    maven 'M2_HOME'
        }

        environment {	
	    DOCKERHUB_CREDENTIALS=credentials('dockerloginid')
	} 
    
    stages {
        stage('SCM Checkout') {
            steps {
                git 'https://github.com/iamanjalibhat/Medicure.git'
            }
        }
        stage('Maven Build') {
            steps {
                // Run Maven on a Unix agent.
                sh "mvn -Dmaven.test.failure.ignore=true clean package"
            }
	}
        stage("Docker build"){
            steps {
		sh 'docker version'
		sh "docker build -t anjalibhat/medicure-app:${BUILD_NUMBER} ."
		sh 'docker image list'
		sh "docker tag anjalibhat/medicure-app:${BUILD_NUMBER} anjalibhat/medicure-app:latest"
            }
        } 
	stage('Login to DockerHub') {
	     steps {
		sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
	     }
	}
	stage('Push to DockerHub') {
             steps {
		sh "docker push anjalibhat/medicure-app:latest"
	     }
	}
    }
}
