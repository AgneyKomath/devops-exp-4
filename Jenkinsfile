pipeline {
  agent any
  environment {
    VENV_DIR = "venv"
    APP_PORT = "5000"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Setup Environment (Windows)') {
      steps {
        bat """
          REM create venv (use py -3 if available)
          py -3 -m venv %VENV_DIR% || python -m venv %VENV_DIR%
          call %VENV_DIR%\\Scripts\\activate.bat
          python -m pip install --upgrade pip
          pip install -r requirements.txt
        """
      }
    }

    stage('Run App (Windows)') {
      steps {
        // call the ps1 that starts the app and waits for /health
        bat "powershell -NoProfile -ExecutionPolicy Bypass -File run_app.ps1 -VenvDir %VENV_DIR% -AppPort %APP_PORT%"
      }
    }

    stage('Run Selenium Tests (Windows)') {
      steps {
        bat """
          call %VENV_DIR%\\Scripts\\activate.bat
          pytest tests/ --maxfail=1 --disable-warnings -q --junitxml=reports\\junit.xml --cov=. --cov-report=xml:reports\\coverage.xml
        """
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
      bat 'powershell -NoProfile -ExecutionPolicy Bypass -File cleanup.ps1'
      junit allowEmptyResults: true, testResults: 'reports\\junit.xml'
    }
    failure {
      bat 'powershell -NoProfile -Command "Write-Host \\"Build failed — check logs\\\\app.log\\"; Get-Content logs\\\\app.log -Tail 200 -ErrorAction SilentlyContinue"'
    }
  }
}
