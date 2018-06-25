def image = 'mlabouardy/oneshot-app'
def registry = 'https://registry.slowcoder.com'

node('slaves'){
    stage('Checkout'){
        checkout scm
    }

    stage('Build'){
        docker.build("${image}")
    }

    stage('Push'){
        docker.withRegistry(registry, 'registry') {
            docker.image(imageName).push("${commitID()}")

            if (env.BRANCH_NAME == 'master') {
              docker.image(imageName).push('latest')
            }
        }
    }

    stage('Deploy'){
        build job: "oneshot-app-deployment/master"
    }
}