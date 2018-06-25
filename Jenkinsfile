def image = 'mlabouardy/oneshot-app'
def registry = 'https://registry.slowcoder.com'

node('slaves'){
    stage('Checkout'){
        checkout scm
    }

    stage('Build'){
        docker.build(image)
    }

    stage('Push'){
        docker.withRegistry(registry, 'registry') {
            docker.image(image).push("${commitID()}")

            if (env.BRANCH_NAME == 'master') {
              docker.image(image).push('latest')
            }
        }
    }

    stage('Deploy'){
        build job: "oneshot-app-deployment/master"
    }
}

def commitID() {
    sh 'git rev-parse HEAD > .git/commitID'
    def commitID = readFile('.git/commitID').trim()
    sh 'rm .git/commitID'
    commitID
}