pipeline {
    agent any
    stages
    {
        stage('test')
        {
            steps
            {
                sh 'pwd'
                sh 'cd $HOME/.jenkins/workspace/Robot_Frame_Work/venv/bin'
                sh 'pwd'
                sh 'echo make output Dir'
                sh 'mkdir -p $WORKSPACE/Output'
                sh '$HOME/.jenkins/workspace/Robot_Frame_Work/venv/bin/./python -m robot -d ./Output/ $HOME/.jenkins/workspace/Robot_Frame_Work/auktion.robot'
            }
        }
        stage('Publish Robot-Test Results')
        {
            steps
            {
                    step([$class: 'RobotPublisher',
                            disableArchiveOutput: false,
                            logFileName: 'log.html',
                            otherFiles: '',
                            outputFileName: 'output.xml',
                            outputPath: './Output/',
                            passThreshold: 100,
                            reportFileName: 'report.html',
                            unstableThreshold: 0]);
            }
        }
    }
}