pipeline {
    agent any
	tools{
	    maven 'M2_HOME'
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
	}
}
