@isTest
public class WhatsappUtilityTest {
    
    private static WhatsappUtility.InputParameters createTestInputParameters(String template, String phone, String mergeRecordName, String mergeFieldName) {
        WhatsappUtility.InputParameters params = new WhatsappUtility.InputParameters();
        params.messagetemplate = template;
        params.phone = phone;
        params.mergeRecordName = mergeRecordName;
        params.mergeFieldName = mergeFieldName;
        return params;
    }

    @isTest static void testSendMessageWithDifferentTemplates() {
        Test.startTest();
        List<WhatsappUtility.InputParameters> paramsList = new List<WhatsappUtility.InputParameters>();
        paramsList.add(createTestInputParameters('deal_status', '1234567890', '001xx000003DIloAAG', 'Paid'));
        paramsList.add(createTestInputParameters('italy_programming', '1234567890', '001xx000003DIloAAH', 'Italy-Programming'));

        WhatsappUtilityMockCallout mockCallout = new WhatsappUtilityMockCallout();
        Test.setMock(HttpCalloutMock.class, mockCallout);

        for (WhatsappUtility.InputParameters params : paramsList) {
            WhatsappUtility.sendMessage(new List<WhatsappUtility.InputParameters>{ params });
        }
        Test.stopTest();
        
        // Retrieve responses from the mock callout
        List<String> responses = mockCallout.getResponses();
        
        System.assertEquals(2, responses.size());
        System.assertEquals('Test message sent successfully for deal_status', responses.get(0));
        System.assertEquals('Test message sent successfully for italy_programming', responses.get(1));
    }

    private class WhatsappUtilityMockCallout implements HttpCalloutMock {
        private List<String> responses = new List<String>();

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            Map<String, Object> template = (Map<String, Object>) ((Map<String, Object>) requestBody.get('template'));

            String responseBody;
            if ((String)template.get('name') == 'italy_programming') {
                responseBody = 'Test message sent successfully for italy_programming';
            } else {
                responseBody = 'Test message sent successfully for deal_status';
            }

            response.setBody('{"success":true, "message":"' + responseBody + '"}');
            response.setStatusCode(200);

            responses.add(responseBody);
            return response;
        }

        public List<String> getResponses() {
            return responses;
        }
    }
}