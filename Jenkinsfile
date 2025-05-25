pipeline {
  agent any
  tools {
    maven 'MAVEN_HOME'
  }
    
  stages {
    stage ('Checkout SCM') {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'git', url: 'https://github.com/champion2010/devopspro_april_2025.git']]])
      }
    }
    
    stage ('Build') {
      steps {
        dir('webapp') {
          sh "pwd"
          sh "ls -lah"
          sh "mvn package"
        }
      }   
    }
   
    stage ('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonar') {
          dir('webapp') {
            sh 'mvn -U clean install sonar:sonar'
          }		
        }
      }
    }

    stage ('Artifactory configuration') {
      steps {
        rtServer (
          id: "jfrog",
          url: "http://13.219.246.71:8082/artifactory", 
          credentialsId: "jfrog"
        )

        rtMavenDeployer (
          id: "MAVEN_DEPLOYER",
          serverId: "jfrog",
          releaseRepo: "project-a-libs-release-local", 
          snapshotRepo: "project-a-libs-snapshot-local" 
        )

        rtMavenResolver (
          id: "MAVEN_RESOLVER",
          serverId: "jfrog",
          releaseRepo: "project-a-libs-release-local",
          snapshotRepo: "project-a-libs-snapshot-local"
        )
      }
    }

    //stage ('Deploy Artifacts') {
    //  steps {
    //    rtMavenRun (
    //      tool: "Maven",
    //      pom: 'webapp/pom.xml',
    //      goals: 'clean install',
    //      deployerId: "MAVEN_DEPLOYER",
    //      resolverId: "MAVEN_RESOLVER"
    //    )
    //  }
    //}

    stage ('Publish build info') {
      steps {
        rtPublishBuildInfo (
          serverId: "jfrog"
        )
      }
    }

    stage('Copy Dockerfile & Playbook to Staging Server') {
      steps {
        sshagent(credentials: ['default-k8s-access']) {
          sh """
            # Set explicit permissions
            chmod 700 ~/.ssh || true
            chmod 600 ~/.ssh/id_rsa || true
            chmod 644 ~/.ssh/id_rsa.pub || true
            chmod 600 workstation-kp.pem || true
            chmod 644 workstation-kp.pem.pub || true
            
            # Copy files
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dockerfile ubuntu@3.235.103.230:/home/ubuntu/
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null push-dockerhub.yaml ubuntu@3.235.103.230:/home/ubuntu/
          """
        }
      }
    } 

    stage('Build Container Image') {
      steps {
        sshagent(credentials: ['default-k8s-access']) {
          sh """
            # Ensure proper permissions
            chmod 600 workstation-kp.pem || true
            
            # Execute remote command
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@3.235.103.230 \
              "ansible-playbook -vvv -e build_number=${BUILD_NUMBER} push-dockerhub.yaml"
          """
        }
      }
    } 

    stage('Copy Deployment & Service Definition to K8s Master') {
      steps {
        sshagent(credentials: ['default-k8s-access']) {
          sh """
            # Copy with explicit permissions
            scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null deploy_service.yaml ubuntu@52.4.164.113:/home/ubuntu/
          """
        }
      }
    } 

    stage('Waiting for Approvals') {
      steps {
        input('Test Completed? Please provide Approvals for Prod Release?')
      }
    }     
    
    stage('Deploy Artifacts to Production') {
      steps {
        sshagent(credentials: ['default-k8s-access']) {
          sh """
            # Apply deployment with explicit permissions
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@52.4.164.113 \
              "kubectl apply -f /home/ubuntu/deploy_service.yaml"
          """
          //sh "ssh -o StrictHostKeyChecking=no ubuntu@52.4.164.113 -C \"kubectl set image deployment/ranty customcontainer=champion2010/devopspro_april_2025:${BUILD_NUMBER}\"" 
          //sh "ssh -o StrictHostKeyChecking=no ubuntu@52.4.164.113 -C \"kubectl delete deployment ranty && kubectl delete service ranty\""
          //sh "ssh -o StrictHostKeyChecking=no ubuntu@52.4.164.113 -C \"kubectl apply -f service.yaml\""
        }
      }  
    } 
  }
  
  post {
    always {
      cleanWs()
    }
    failure {
      emailext body: 'Build ${BUILD_NUMBER} failed. See ${BUILD_URL}',
              subject: 'Build Failed: ${JOB_NAME}',
              to: 'team@example.com'
    }
  }
}
