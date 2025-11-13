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
        script {
          if (isUnix()) {
            sh '''
              python3 -m venv $VENV_DIR
              . $VENV_DIR/bin/activate
              pip install --upgrade pip
              pip install -r requirements.txt
            '''
          } else {
            // Windows
            bat """
              python -m venv %VENV_DIR%
              call %VENV_DIR%\\Scripts\\activate.bat
              python -m pip install --upgrade pip
              pip install -r requirements.txt
            """
          }
        }
      }
    }

    stage('Run App') {
      steps {
        script {
          if (isUnix()) {
            sh '''
              set -e
              . $VENV_DIR/bin/activate
              mkdir -p logs reports
              nohup $VENV_DIR/bin/python app.py > logs/app.log 2>&1 &
              echo $! > app.pid
              # poll health
              timeout=15; i=0
              while [ $i -lt $timeout ]; do
                if curl -sS http://127.0.0.1:$APP_PORT/health >/dev/null 2>&1; then break; fi
                sleep 1; i=$((i+1))
              done
              if [ $i -ge $timeout ]; then echo "App failed to start"; tail -n +1 logs/app.log; exit 1; fi
            '''
          } else {
            // Windows: start Python in background and capture PID via PowerShell
            bat '''
              powershell -NoProfile -Command ^
                "mkdir -Force logs, reports; ^
                 $p = Start-Process -FilePath python -ArgumentList 'app.py' -PassThru -WindowStyle Hidden; ^
                 $p.Id > app.pid; ^
                 $timeout = 15; $i = 0; ^
                 while ($i -lt $timeout) { ^
                   try { Invoke-RestMethod -UseBasicParsing http://127.0.0.1:5000/health -TimeoutSec 2; break } catch { Start-Sleep -Seconds 1; $i++ } ^
                 }; ^
                 if ($i -ge $timeout) { Get-Content logs\\app.log -ErrorAction SilentlyContinue; exit 1 }"
            '''
          }
        }
      }
    }

    stage('Run Selenium Tests') {
      steps {
        script {
          if (isUnix()) {
            sh '''
              . $VENV_DIR/bin/activate
              mkdir -p reports
              pytest tests/ --maxfail=1 --disable-warnings -q \
                --junitxml=reports/junit.xml \
                --cov=. --cov-report=xml:reports/coverage.xml
            '''
          } else {
            bat '''
              call %VENV_DIR%\\Scripts\\activate.bat
              powershell -NoProfile -Command "mkdir -Force reports"
              pytest tests/ --maxfail=1 --disable-warnings -q --junitxml=reports/junit.xml --cov=. --cov-report=xml:reports/coverage.xml
            '''
          }
        }
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
      script {
        if (isUnix()) {
          sh '''
            if [ -f app.pid ]; then kill $(cat app.pid) || true; rm -f app.pid; fi
          '''
        } else {
          bat '''
            powershell -NoProfile -Command ^
              "if (Test-Path app.pid) { ^
                 $pid = Get-Content app.pid; ^
                 Try { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } Catch {}; ^
                 Remove-Item app.pid -ErrorAction SilentlyContinue }"
          '''
        }
      }
      // publish junit / archive artifacts
      junit allowEmptyResults: true, testResults: 'reports/junit.xml'
    }
    failure {
      script {
        if (isUnix()) {
          sh 'echo "Build failed — check logs/app.log"; tail -n 200 logs/app.log || true'
        } else {
          bat 'powershell -NoProfile -Command "Write-Host \\"Build failed — check logs\\app.log\\"; Get-Content logs\\app.log -Tail 200 -ErrorAction SilentlyContinue"'
        }
      }
    }
  }
}
