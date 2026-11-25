pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  triggers { githubPush() }

  environment {
    REGISTRY   = 'ghcr.io/tuantetua123'
    COMPOSE    = 'docker compose --env-file .env.example'
    CI_PROJECT = "attendance-ci-${env.BUILD_NUMBER}"
    WEB_PORT   = '18090'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.TAG = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
          env.GIT_SHA = env.TAG
        }
        echo "Building commit ${env.TAG}"
      }
    }

    stage('Secret scan') {
      steps {
        sh '''
          docker run --rm -v "$WORKSPACE":/repo ghcr.io/gitleaks/gitleaks:v8.21.2 \
            detect --source=/repo --redact --exit-code 1
        '''
      }
    }

    stage('Lint') {
      parallel {
        stage('Python (ruff)') {
          steps {
            sh '''
              docker run --rm -v "$WORKSPACE":/w -w /w ghcr.io/astral-sh/ruff:0.8.4 \
                check api/app qr/app
            '''
          }
        }
        stage('Dockerfiles (hadolint)') {
          steps {
            sh '''
              for svc in api qr web; do
                docker run --rm -i hadolint/hadolint:v2.12.0 hadolint --failure-threshold error - < "$svc/Dockerfile"
              done
            '''
          }
        }
      }
    }

    stage('Unit test') {
      steps {
        sh '''
          for svc in api qr; do
            if [ -d "$svc/tests" ]; then
              docker run --rm -v "$WORKSPACE/$svc":/w -w /w -e PYTHONPATH=/w:/w/app python:3.12-slim \
                sh -c "pip install -q -r requirements.txt && ([ -f requirements-dev.txt ] && pip install -q -r requirements-dev.txt || pip install -q pytest) && python -m pytest -q tests"
            fi
          done
        '''
      }
    }

    stage('Build images') {
      steps {
        sh '$COMPOSE build'
      }
    }

    stage('Integration test') {
      steps {
        sh '$COMPOSE -p $CI_PROJECT -f compose.yml -f compose.test.yml run --rm smoke'
      }
      post {
        always {
          sh '$COMPOSE -p $CI_PROJECT -f compose.yml -f compose.test.yml down -v || true'
        }
      }
    }

    stage('Security scan (Trivy)') {
      steps {
        sh '''
          for svc in api qr web; do
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.57.1 \
              image --exit-code 1 --severity CRITICAL --ignore-unfixed "$REGISTRY/attendance-$svc:$TAG"
          done
        '''
      }
    }

    stage('Push images') {
      when { expression { env.BRANCH_NAME == 'main' || (env.GIT_BRANCH ?: '').endsWith('/main') } }
      steps {
        withCredentials([usernamePassword(credentialsId: 'ghcr-creds', usernameVariable: 'GH_USER', passwordVariable: 'GH_TOKEN')]) {
          sh '''
            echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
            $COMPOSE push api qr web
          '''
        }
      }
    }

    stage('Deploy staging') {
      when {
        allOf {
          expression { env.BRANCH_NAME == 'main' || (env.GIT_BRANCH ?: '').endsWith('/main') }
          expression { fileExists('k8s') }
        }
      }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            kubectl apply -f k8s/namespaces.yaml
            kubectl -n staging create configmap db-migrations --from-file=db/migrations --dry-run=client -o yaml | kubectl -n staging apply -f -
            kubectl -n staging create configmap db-seed-data --from-file=db/seed --dry-run=client -o yaml | kubectl -n staging apply -f -

            MIGRATE_JOB=$(kubectl -n staging create -f k8s/jobs/migrate-job.yaml -o name)
            kubectl -n staging wait --for=condition=complete "$MIGRATE_JOB" --timeout=90s

            SEED_JOB=$(kubectl -n staging create -f k8s/jobs/seed-job.yaml -o name)
            kubectl -n staging wait --for=condition=complete "$SEED_JOB" --timeout=90s

            kubectl apply -k k8s/overlays/staging
            for svc in api qr web; do
              kubectl -n staging set image deployment/$svc $svc=$REGISTRY/attendance-$svc:$TAG
              kubectl -n staging rollout status deployment/$svc --timeout=120s
            done
          '''
        }
      }
    }

    stage('Approve production') {
      when {
        allOf {
          expression { env.BRANCH_NAME == 'main' || (env.GIT_BRANCH ?: '').endsWith('/main') }
          expression { fileExists('k8s') }
        }
      }
      steps {
        timeout(time: 1, unit: 'HOURS') {
          input message: "Deploy ${env.TAG} to PRODUCTION?", ok: 'Deploy'
        }
      }
    }

    stage('Deploy production') {
      when {
        allOf {
          expression { env.BRANCH_NAME == 'main' || (env.GIT_BRANCH ?: '').endsWith('/main') }
          expression { fileExists('k8s') }
        }
      }
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            kubectl -n production create configmap db-migrations --from-file=db/migrations --dry-run=client -o yaml | kubectl -n production apply -f -

            MIGRATE_JOB=$(kubectl -n production create -f k8s/jobs/migrate-job.yaml -o name)
            kubectl -n production wait --for=condition=complete "$MIGRATE_JOB" --timeout=90s

            kubectl apply -k k8s/overlays/production
            for svc in api qr web; do
              kubectl -n production set image deployment/$svc $svc=$REGISTRY/attendance-$svc:$TAG
              kubectl -n production rollout status deployment/$svc --timeout=120s
            done
          '''
        }
      }
    }
  }

  post {
    always {
      script {
        try {
          withCredentials([string(credentialsId: 'telegram-token', variable: 'TG_TOKEN'),
                           string(credentialsId: 'telegram-chat-id', variable: 'TG_CHAT')]) {
            def msg = "${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER} (${env.TAG}) ${env.BUILD_URL}"
            sh "curl -s -X POST https://api.telegram.org/bot\$TG_TOKEN/sendMessage -d chat_id=\$TG_CHAT --data-urlencode text='${msg}' || true"
          }
        } catch (err) {
          echo 'Telegram credentials not configured yet, skipping notification.'
        }
      }
    }
  }
}