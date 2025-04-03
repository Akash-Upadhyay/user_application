#!/bin/bash

# Script to set up Jenkins for microservices application CI/CD

# Install required plugins
JENKINS_HOST="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASS="your_jenkins_password"  # Change this to your actual Jenkins password

echo "Installing required Jenkins plugins..."
PLUGINS=(
    "git"                         # Git integration
    "pipeline"                    # Pipeline support
    "docker-workflow"             # Docker integration
    "kubernetes"                  # Kubernetes integration
    "ansible"                     # Ansible integration
    "credentials-binding"         # Credentials binding
)

for plugin in "${PLUGINS[@]}"; do
    echo "Installing $plugin plugin..."
    java -jar jenkins-cli.jar -s $JENKINS_HOST -auth $JENKINS_USER:$JENKINS_PASS install-plugin $plugin
done

echo "Restarting Jenkins to apply plugin changes..."
java -jar jenkins-cli.jar -s $JENKINS_HOST -auth $JENKINS_USER:$JENKINS_PASS safe-restart

echo "Waiting for Jenkins to restart..."
sleep 60

# Create credentials for Docker Hub
echo "Creating Docker Hub credentials..."
cat <<EOF > create_docker_creds.groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

def createDockerhubCredentials() {
    def domain = Domain.global()
    def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

    def credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        'docker-hub-credentials',
        'Docker Hub Credentials',
        'yourdockerhubusername',  // Change this to your Docker Hub username
        'yourdockerhubpassword'   // Change this to your Docker Hub password
    )
    
    store.addCredentials(domain, credentials)
    return true
}

createDockerhubCredentials()
EOF

java -jar jenkins-cli.jar -s $JENKINS_HOST -auth $JENKINS_USER:$JENKINS_PASS groovy = < create_docker_creds.groovy
rm create_docker_creds.groovy

# Create Jenkins pipeline job
echo "Creating Jenkins pipeline job..."
cat <<EOF > create_pipeline_job.xml
<?xml version="1.0" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.40">
  <description>Microservices Application CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.7.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/yourusername/microservices-app.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

java -jar jenkins-cli.jar -s $JENKINS_HOST -auth $JENKINS_USER:$JENKINS_PASS create-job microservices-app < create_pipeline_job.xml
rm create_pipeline_job.xml

echo "Jenkins setup completed successfully!"
echo "You can now access the Jenkins pipeline at: $JENKINS_HOST/job/microservices-app/"
echo "Make sure to update the GitHub repository URL and Docker Hub credentials with your actual values." 