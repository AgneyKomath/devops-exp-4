pipeline {
  agent any
  environment {
    VENV_DIR = "venv"
    APP_PORT  = "5000"
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Setup Environment') {
      steps {
        sh '''
          python3 -m venv $VENV_DIR
          . $VENV_DIR/bin/activate
          pip install --upgrade pip
          pip install -r requirements.txt
        '''
      }
    }

    stage('Run App') {
      steps {
        sh '''
          set -e
          . $VENV_DIR/bin/activate
          # ensure logs and reports dirs exist
          mkdir -p logs reports
          # run app in background and save PID
          nohup $VENV_DIR/bin/python app.py > logs/app.log 2>&1 &
          echo $! > app.pid
          # poll health endpoint until ready (15s timeout)
          timeout=15
          i=0
          while [ $i -lt $timeout ]; do
            if curl -sS http://127.0.0.1:$APP_PORT/health >/dev/null 2>&1; then
              echo "App is up"
              break
            fi
            sleep 1
            i=$((i+1))
          done
          if [ $i -ge $timeout ]; then
            echo "App failed to start"
            tail -n +1 logs/app.log || true
            exit 1
          fi
        '''
      }
    }

    stage('Run Selenium Tests') {
      steps {
        sh '''
          . $VENV_DIR/bin/activate
          mkdir -p reports
          # run tests and generate junit + coverage xml
          pytest tests/ --maxfail=1 --disable-warnings -q \
            --junitxml=reports/junit.xml \
            --cov=. --cov-report=xml:reports/coverage.xml
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'reports/**, logs/**', allowEmptyArchive: true
        }
      }
    }
  }

  post {
    always {
      sh '''
        # stop the app if running
        if [ -f app.pid ]; then
          kill $(cat app.pid) || true
          rm -f app.pid
        fi
      '''
      // publish junit results (fails the build if file missing? Jenkins handles missing)
      junit allowEmptyResults: true, testResults: 'reports/junit.xml'
      // coverage publishing depends on plugin; at minimum we archived coverage.xml
    }
    failure {
      sh 'echo "Build failed — check logs/app.log and reports"; tail -n 200 logs/app.log || true'
    }
  }
}
