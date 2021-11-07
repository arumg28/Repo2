*** Settings ***
Library           Collections
Library           String
Library           OperatingSystem
Library           robot.api.logger
Library           SSHLibrary
Library           SeleniumLibrary

*** Test Cases ***
TC_UNIX_CON
    [Template]    ASSIGN_UNIX_CONNECTION FOR ${ENVIRONMENT}
    QA

*** Keywords ***
ASSIGN_UNIX_CONNECTION FOR ${ENVIRONMENT}
    #    #    USERNAME    SERVER_NAME    PROMPT_NAME    PASSWORD
    @{QA_Details}    Create List    arun    10.345,176,177    USER:    pass
    ${Env_Dict}    Create Dictionary    QA=@{QA_Details}
    @{Unix_Details}    Get From Dictionary    ${Env_Dict}    ${ENVIRONMENT}
    Set Log Level    NONE
    Set Suite Variable    ${UNIX_USERNAME}    @{Unix_Details}[0]
    Set Suite Variable    ${SERVER_NAME}    @{Unix_Details}[1]
    Set Log Level    INFO
    console    '${UNIX_USERNAME}'
    [Teardown]    Set Global Variable    ${ENVIRONMENT}

WRITE COMMAND IN UNIX AND WAIT UNTIL PROMPT
    [Arguments]    ${command}
    log    ${command}
    SSHLibrary.Write    ${command}
    ${out}    Read Until    ${MY_PROMPT}
    @{Status}    Run Keyword And Ignore Error    Should Not Contain    ${out}    No Space left on the device
    @{Status1}    Run Keyword And Ignore Error    Should Not Contain    ${out}    Disk Quota exceeded
    Run Keyword If    '@{Status}[0]' =='Fail'    fail    Error occured in Running command [${command}]\nError : no space left on the device
    Run Keyword If    '@{Status1}[0]' =='Fail'    fail    Error occured in Running command [${command}]\nError : Disk quota exceeded
    [Return]    ${out}

OPEN UNIX CONNECTION
    Run Keyword And Ignore Error    Close Connection
    SSHLibrary.Open Connection    ${UNIX_HOST}
    SSHLibrary.Login    ${UNIX_USERNAME}    ${UNIX_PASSWORD}
    Set Client Configuration    25s
    Set Suite Variable    ${MY_PROMPT}    ${UNIX_USERNAME}:
    SSHLibrary.Write    PS1="${MY_PROMPT}"
    Read Until    ${MY_PROMPT}

RUN GIVEN QUERIES IN ORACLE
    ${faillist}    Create List
    console    \nRunning queries in ${ environemtn}
    SSHLibrary.Write    sqlplus / as sysdba
    Read Until    SQL>
    Set Client Configuration    2m
    : FOR    ${queryFile}    IN    @{TEMP_LIST}
    \    console    \nExecuting ${queryFile}
    \    SSHLibrary.Write    @{UNIX_ORACLE_LOCATION}/${queryFile}
    \    ${query_out}    Read Until    spool off;
    \    ${error}    Get Lines Containing String    ${query_out}    ORA-
    \    @{stat}    Run Keyword And Ignore Error    Should Be Empty    ${error}
    \    @{already_exist}    Run Keyword And Ignore Error    Should Not Contain    ${error}    ORA-01430
    \    Run Keyword if    '@{stat}[0]'=='Fail' and '@{already_exist}[0]'=='PASS'    Append To List    ${faillist}    ${queryFile}
    \    Run Keyword if    '@{stat}[0]'=='Fail'    console    Query Execution Failed\nReason:{error}
    \    ...    ELSE    console    Query ran without any error
    SSHLibrary.Write    quit
    Read Until    $
    ${Listlength}    Get length    ${faillist}
    Run Keyword if    ${Listlength}==0    Pass Execution    All queries ran without any errors
    ...    ELSE    fail    [${Listlength}] queries failed while deploying

SCP FILE TRANSFER TO GIVEN LOCATION
    [Arguments]    ${SCP_SERVER}    ${SCP_COMMAND}
    ASSIGN_UNIX_CONNECTION FOR ${SCP_SERVER}
    ${SCP_COMMAND}    Replace String    ${SCP_COMMAND}    [USER]    ${UNIX_USERNAME}
    ${SCP_COMMAND}    Replace String    ${SCP_COMMAND}    [HOST]    ${UNIX_HOST}
    Set Client Configuration    3m
    SSHLibrary.Write    ${SCP_COMMAND}
    Read Until    password:
    Set Log Level    NONE
    ${Out}    WRITE COMMAND IN UNIX AND WAIT UNTIL PROMPT    ${UNIX_PASSWORD}
    Set Log Level    INFO
    log    ${Out}
    @{Scp_stst}    Run Keyword And Ignore Error    Should Contain    ${Out}    100%
    Run Keyword If    '@{Scp_stst} [0]'=='PASS'    console    SCP Command completed successfully to $SCP_SERVER} server
    ...    ELSE    fail    SCP File transfer failed to $[SCP_SERVER} server

CREATE WEBDRIVER FOR GIVEN BROWSER
    [Arguments]    ${browser}
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, seleniuim.webdriver
    Call Method    ${options}    add_argument    --start-maximized
    Call Method    ${options}    add_experimental_option    useAutomationExtension    ${False}
    Call Method    ${options}    add_argument    headless
    Call Method    ${options}    add_argument    no-sandbox
    Create WebDriver    ${browser}    chrome_options=${options}

LOGON TO WEBSITE
    CHECK AUTHENTICATION FILE EXISTS    ${LOGON_FAIL_FILE}/${Autosys_username}.txt    ${user_name}    ${password}    Auto
    Delete All Cookies
    Set Selenium Speed    .5
    SeleniumLibrary.Set Window Size    1400    1200

CHECK AUTHENTICATION FILE EXISTS
    [Arguments]    ${file}    ${user}    ${password}    ${server}
    ${file_name_temp}    Fetch From Right    ${file}    /
    ${state}    Run Keyword And Return Status    OperatingSystem.File Should Not Exist    ${file}
    Return From Keyword If    '${state}'=='True'
    ${password_in_file}    OperatingSystem.Get File    ${file}
    Run Keyword If    '${password_in_file}'=='${password}'    fail    Authentication Failed [${server}] for user [${user}] with given password in last run
    Run Keyword Unless    '${password_in_file}'=='${password}'    Remove File    ${file}
