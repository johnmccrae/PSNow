Feature: You can copy one file

Scenario: The file exists, and the target folder exists    
    Given we have a source file    
    And we have a destination folder    
    When we call Copy-Item    
    Then we have a new file in the destination    
    And the new file is the same as the original file