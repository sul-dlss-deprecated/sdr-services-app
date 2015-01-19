
# Note: the -test db is cleaned around every scenario by DatabaseCleaner, see
# /data/src/dlss/sdr-services-app/features/support/database_cleaner.rb

@api
Feature: List digital_objects
  As an API client
  In order to do things with digital_objects
  I want to retrieve a list of digital_objects

  Scenario Outline: retrieve digital_objects
    Given I am a valid API user
    And I send and accept "<mime_type>"
    And I have <rows> of "<child_element>" records
    When I send a GET request for "<path>"
    Then the response should be "<status>"
    And the "<mime_type>" response should have a "<root_element>" array
    And the "<mime_type>" response should have <rows> of "<child_element>" elements
  Examples:
    | path                     | mime_type | root_element    | child_element  | status | rows |
    | /archive/digital_objects | XML       | digital-objects | digital-object | 200    | 0    |
    | /archive/digital_objects | JSON      | digital-objects | digital-object | 200    | 0    |
    | /archive/digital_objects | XML       | digital-objects | digital-object | 200    | 5    |
    | /archive/digital_objects | JSON      | digital-objects | digital-object | 200    | 5    |

  Scenario Outline: retrieve digital_objects in repository
    Given I am a valid API user
    And I send and accept "<mime_type>"
    And I have <rows> of "<child_element>" records in "<data_repo>" repository
    When I send a GET request for "<path>"
    Then the response should be "<status>"
    And the "<mime_type>" response should have a "<root_element>" array
    And the "<mime_type>" response should <count> "<child_element>" elements with "sdr" repository
  Examples:
    | path                           | data_repo  | mime_type | root_element    | child_element  | status | rows | count |
    | /archive/digital_objects/sdr   | other      | XML       | digital-objects | digital-object | 200    | 5    | 0     |
    | /archive/digital_objects/sdr   | other      | JSON      | digital-objects | digital-object | 200    | 5    | 0     |
    | /archive/digital_objects/sdr   | sdr        | XML       | digital-objects | digital-object | 200    | 0    | 0     |
    | /archive/digital_objects/sdr   | sdr        | JSON      | digital-objects | digital-object | 200    | 0    | 0     |
    | /archive/digital_objects/sdr   | sdr        | XML       | digital-objects | digital-object | 200    | 5    | 5     |
    | /archive/digital_objects/sdr   | sdr        | JSON      | digital-objects | digital-object | 200    | 5    | 5     |

