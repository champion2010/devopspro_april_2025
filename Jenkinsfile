pipeline {
  agent any
  tools {
    maven 'MAVEN_HOME'
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout([$class: 'GitSCM', 
                 branches: [[name: '*/master']], 
                 doGenerateSubmoduleConfigurations: false, 
                 extensions: [], 
                 submoduleCfg: [], 
                 userRemoteConfigs: [[credentialsId: 'git', 
                                    url: 'https://github.com/champion2010/devopspro_april_2025.git']]])
      }
    }

    stage('Build') {
      steps {
        dir('webapp') {
          sh "pwd"
          sh "ls -lah"
          sh "mvn package"
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonar') {
          dir('webapp') {
            sh 'mvn -U clean install sonar:sonar'
          }
        }
      }
    }

    stage('Artifactory configuration') {
      steps {
        rtServer(
          id: "jfrog",
          url: "http://13.219.246.71:8082/artifactory",
          credentialsId: "jfrog"
        )

        rtMavenDeployer(
          id: "MAVEN_DEPLOYER",
          serverId: "jfrog",
          releaseRepo: "project-a-libs-release-local",
          snapshotRepo: "project-a-libs-snapshot-local"
        )

        rtMavenResolver(
          id: "MAVEN_RESOLVER",
          serverId: "jfrog",
          releaseRepo: "project-a-libs-release-local",
          snapshotRepo: "project-a-libs-snapshot-local"
        )
      }
    }

    stage('Publish build info') {
      steps {
        rtPublishBuildInfo(
          serverId: "jfrog"
        )
      }
    }

    stage('Copy Dockerfile & Playbook to Staging Server') {
      steps {
        sshagent(['ssh_agent']) {
          sh "chmod 400 workstation-kp.pem"
          sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i workstation-kp.pem dockerfile ubuntu@3.235.103.230:/home/ubuntu"
          sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i workstation-kp.pem push-dockerhub.yaml ubuntu@3.235.103.230:/home/ubuntu"
        }
      }
    }

    stage('Build Container Image') {
      steps {
        sshagent(['ssh_agent']) {
          sh "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i workstation-kp.pem ubuntu@3.235.103.230 \"ansible-playbook -vvv -e build_number=${BUILD_NUMBER} push-dockerhub.yaml\""
        }
      }
    }

    stage('Copy Deployment & Service Definition to K8s Master') {
      steps {
        sshagent(['ssh_agent']) {
          sh "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i workstation-kp.pem deploy_service.yaml ubuntu@52.4.164.113:/home/ubuntu"
        }
      }
    }

    stage('Waiting for Approvals') {
      steps {
        input(message: 'Test Completed? Please provide Approvals for Prod Release', ok: 'Deploy to Production')
      }
    }

    stage('Deploy Artifacts to Production') {
      steps {
        sshagent(['ssh_agent']) {
          sh "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i workstation-kp.pem ubuntu@52.4.164.113 \"kubectl apply -f /home/ubuntu/deploy_service.yaml\""
        }
      }
    }
  }
}
