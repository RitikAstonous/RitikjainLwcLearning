public with sharing class WhatsappUtility {


        public class InputParameters {
            @InvocableVariable(label='Whatsapp Template' description='The message to be sent via WhatsApp')
            public String messagetemplate;
    
            @InvocableVariable(label='Phone Number' description='The phone number to send the WhatsApp message to')
            public String phone;
    
            @InvocableVariable(label='Merge Record Name' description='The ID of the record related to this message')
            public String mergeRecordName;
    
            @InvocableVariable(label='Merge Field Name' description='The ID of the record related to this message')
            public String mergeFieldName;
        }
    
        @InvocableMethod(label='Send WhatsApp Message' description='This method sends a WhatsApp message using specified parameters.')
        public static void sendMessage(List<InputParameters> inputParamsList) {
            if (inputParamsList.isEmpty()) {
                return;
            }
    
            InputParameters inputParams = inputParamsList.get(0);
    
            if (System.isBatch()) {
                sendMessage(inputParams.messagetemplate, inputParams.phone, inputParams.mergeRecordName, inputParams.mergeFieldName);
            } else {
                sendMessageAsync(inputParams.messagetemplate, inputParams.phone, inputParams.mergeRecordName, inputParams.mergeFieldName);
            }
        }
    
        @future(callout=true)
        public static void sendMessageAsync(String messagetemplate, String phone, String mergeRecordName, String mergeFieldName) {
            sendMessage(messagetemplate, phone, mergeRecordName, mergeFieldName);
        }
    
        private static void sendMessage(String messagetemplate, String phone, String mergeRecordName, String mergeFieldName) {
            Whatsapp_Configuration__mdt credential = fetchWhatsappCredential();
    
            HttpRequest req = constructHttpRequest(messagetemplate, phone, mergeRecordName, mergeFieldName, credential);
    
            sendHttpRequest(req);
        }
    
        private static Whatsapp_Configuration__mdt fetchWhatsappCredential() {
            List<Whatsapp_Configuration__mdt> mdt = [SELECT Id, Permanent_Token__c, Endpoint__c FROM Whatsapp_Configuration__mdt LIMIT 1];
            return mdt.isEmpty() ? null : mdt[0];
        }
    
        private static HttpRequest constructHttpRequest(String messagetemplate, String phone, String mergeRecordName, String mergeFieldName, Whatsapp_Configuration__mdt credential) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(credential.Endpoint__c);
            req.setMethod('POST');
            req.setHeader('Authorization', credential.Permanent_Token__c);
            req.setHeader('Content-Type', 'application/json');
    
            Map<String, Object> body = constructRequestBody(messagetemplate, phone, mergeRecordName, mergeFieldName);
    
            req.setBody(JSON.serialize(body));
    
            return req;
        }
    
        private static Map<String, Object> constructRequestBody(String messagetemplate, String phone, String mergeRecordName, String mergeFieldName) {
            Map<String, Object> templateData = new Map<String, Object>{
                'namespace' => '614bcec3_b86c_427a_a3f9_1f49b44cdfa6',
                'name' => messagetemplate,
                'language' => new Map<String, String>{'code' => 'en_US'}
            };

            templateData.put('components', new List<Map<String, Object>>{
                    new Map<String, Object>{
                        'type' => 'body',
                        'parameters' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'type' => 'text',
                                'text' => mergeRecordName
                            },
                            new Map<String, Object>{
                                'type' => 'text',
                                'text' => mergeFieldName
                            }
                        }
                    }
                });
        
            return new Map<String, Object>{
                'messaging_product' => 'whatsapp',
                'recipient_type' => 'individual',
                'to' => phone,
                'type' => 'template',
                'template' => templateData
            };
        }
        
    
        private static void sendHttpRequest(HttpRequest req) {
            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                System.debug(res.getBody());
                if (res.getStatusCode() == 200) {
                    System.debug('Message sent successfully');
                } else {
                    System.debug('Error sending message: ' + res.getStatus());
                }
            } catch (Exception e) {
                System.debug('Exception in sending message: ' + e.getMessage());
            }
        }
    
       
}