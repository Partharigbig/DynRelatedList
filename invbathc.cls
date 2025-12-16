/******************************************************************************************
Purpose : Class for Generating the Document using SF DocGen.
Name    : MC_InvoiceDocumentGenerationBatchClass
Author  : Cognizant
Version : 1.0 

Modification History
Date          Who        Description  test

******************************************************************************************/

global class MC_InvoiceDocumentGenerationBatchClass implements database.batchable<sObject>, Database.stateful {
        List<Document_Mappings__c> documentMappingsList;
        Map<String, String> docTemplateMap = new Map<String, String>();
        Map<String, String> templateNameContentDocIdMap = new Map<String, String>();
        private String csvContent = '';
   		private Integer invoiceCount = 0;
        //List<DocumentGenerationProcess> failedDGRecords = new List<DocumentGenerationProcess>();
    	//private List<maica_cc__Invoice__c> invoicesToUpdate = new List<maica_cc__Invoice__c>();
     	
        private Boolean isRetry;
        public MC_InvoiceDocumentGenerationBatchClass(Boolean isRetry) {
            this.isRetry = isRetry;
        }
//++++++++++++++++++++++++++++++++++++++++Start Method**************************************************    
       global Database.queryLocator start(Database.BatchableContext bc) {
           
            documentMappingsList = [SELECT Id, Document_Token__c, Is_Parent_Object_Mapping__c,Is_Child_Object_Mapping__c,Is_Unrelated_Object_Mapping__c,Unrelated_Object_Name__c, Token_Value__c, Document_Name__c, Data_Type__c, Name 
                                                                   FROM Document_Mappings__c WHERE Document_Name__c = 'Invoice_Template'];
                
             List<DocumentTemplate> docTemplateList = [ SELECT Id, Name FROM DocumentTemplate 
                                                        WHERE Name LIKE '%Invoice_Template%'
                                                        AND IsActive = true];
             
            List<Environment_Variables__mdt> envVariblesList = [SELECT Id,Value__c,DeveloperName FROM Environment_Variables__mdt
                                                               WHERE DeveloperName Like '%Invoice_Template%' Limit 1];
            
            List<ContentVersion> contentVersionList = [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId =: envVariblesList[0].Value__c];
            for(ContentVersion cv : contentVersionList){
                templateNameContentDocIdMap.put('Invoice_Template1', cv.Id);
                
            }
            docTemplateMap = new Map<String, String>();
            for(DocumentTemplate docTemplate : docTemplateList){
                docTemplateMap.put('Invoice_Template1', docTemplate.Id);
            }
            
            List<maica_cc__Invoice__c> invObj = [select Id from maica_cc__Invoice__c where maica_cc__Participant__r.AccountId  = '001Bm00000lzLCXIA2' limit 500];
            List<Id> invList = new List<Id>();
            for(maica_cc__Invoice__c inv : invObj){
                invList.add(inv.Id);
            }
           String query= 'SELECT Id, Name, maica_cc__Funding_Type__c, Service_Ref__c, maica_cc__Funding_Administrator__c,maica_cc__Funding_Administrator__r.Billing_Communication_Preference__c, maica_cc__Invoice_Date__c, ' +
                        'maica_cc__Total_Amount__c, Invoice_Number__c, Account_Name__r.Id, Account_Name__r.maica_cc__NDIS_Number__pc,Account_Name__r.FirstName, Account_Name__r.LastName,maica_cc__Dispatch_Status__c, '+
                        'Account_Name__r.Name, Account_Name__r.BillingStreet,Communication_Preference__c,Account_Name__r.Opted_for_Direct_Debit__c, ' +
                        'Total_GST__c, BPAY_Reference_Number__c, Account_Name__r.BillingCity, Account_Name__r.BillingState, Account_Name__r.BillingPostalCode, ' +
                        'Account_Name__r.mecwacare_Client_ID__c, Account_Name__r.PersonEmail, Total_Amount_Ex_GST__c, Account_Name__r.Days_Overdue_1__c, ' +
                        'Account_Name__r.Days_Overdue_2__c, Account_Name__r.Days_Overdue_3__c, Account_Name__r.Days_OverDue_4__c, maica_cc__Due_Date__c, ' +
                        'maica_cc__Participant__c, Biller_Code__c, Account_Name__r.Unapplied_Payment__c, Account_Name__r.Balance_Due__c, Account_Name__c, ' +
                        'Invoice_Type__c, Payment_Terms_for_Doc1__c, Payment_Terms_for_Doc__c, Account_Name__r.Unapplied_Payments__c,MC_Billing_Contact_Name__c,BillingOrganisation__c, ' +
                        '(SELECT Id, maica_cc__Invoice__c, maica_cc__Quantity__c, maica_cc__Unit_Price__c, maica_cc__GST_Amount__c, maica_cc__Amount__c, ' +
                        'maica_cc__Line_Total__c, Service_Detail_Description__c, maica_cc__Support_Item__r.Name FROM maica_cc__Invoice_Line_Items__r) ' +
                		'FROM maica_cc__Invoice__c where Id = \'a0XBm000005zBy9MAE\'';
               //NOT IN (\'Voided\', \'Cancelled\') AND Id In: invList';
           
               if(isRetry) {
                List<Mecwa_ExceptionLog__c> excepRec = [SELECT Id,Invoice_Record_Id__c,Exception_Message__c FROM Mecwa_ExceptionLog__c where Invoice_Record_Id__c != null AND (Error_Type__c = 'Document' OR Error_Type__c = 'Post' ) AND CreatedDate = YESTERDAY];
                Set<Id> invoiceIdsFromInvoices = new Set<Id>();
                
                for (Mecwa_ExceptionLog__c exc : excepRec) {
                    invoiceIdsFromInvoices.add(exc.Invoice_Record_Id__c);
                }
                 query = 'SELECT Id, Name, maica_cc__Funding_Type__c, Service_Ref__c, maica_cc__Funding_Administrator__c,maica_cc__Funding_Administrator__r.Billing_Communication_Preference__c, maica_cc__Invoice_Date__c, ' +
                        'maica_cc__Total_Amount__c, Invoice_Number__c, Account_Name__r.Id, Account_Name__r.maica_cc__NDIS_Number__pc,Account_Name__r.FirstName, Account_Name__r.LastName,maica_cc__Dispatch_Status__c, '+
                        'Account_Name__r.Name, Account_Name__r.BillingStreet,Communication_Preference__c,Account_Name__r.Opted_for_Direct_Debit__c, ' +
                        'Total_GST__c, BPAY_Reference_Number__c, Account_Name__r.BillingCity, Account_Name__r.BillingState, Account_Name__r.BillingPostalCode, ' +
                        'Account_Name__r.mecwacare_Client_ID__c, Account_Name__r.PersonEmail, Total_Amount_Ex_GST__c, Account_Name__r.Days_Overdue_1__c, ' +
                        'Account_Name__r.Days_Overdue_2__c, Account_Name__r.Days_Overdue_3__c, Account_Name__r.Days_OverDue_4__c, maica_cc__Due_Date__c, ' +
                        'maica_cc__Participant__c, Biller_Code__c, Account_Name__r.Unapplied_Payment__c, Account_Name__r.Balance_Due__c, Account_Name__c, ' +
                        'Invoice_Type__c, Payment_Terms_for_Doc1__c, Payment_Terms_for_Doc__c, Account_Name__r.Unapplied_Payments__c,MC_Billing_Contact_Name__c,BillingOrganisation__c, ' +
                        '(SELECT Id, maica_cc__Invoice__c, maica_cc__Quantity__c, maica_cc__Unit_Price__c, maica_cc__GST_Amount__c, maica_cc__Amount__c, ' +
                        'maica_cc__Line_Total__c, Service_Detail_Description__c, maica_cc__Support_Item__r.Name FROM maica_cc__Invoice_Line_Items__r) ' +
                		'FROM maica_cc__Invoice__c where Id In : invoiceIdsFromInvoices' ;
                      
                //query += ' AND Id In: invoiceIdsFromInvoices';
                System.debug('query============'+query);
            
            }
                //Id = \'a0XBm000005nHw5MAE\' OR Id = \'a0XBm000005lisTMAQ\' OR Id = \'a0XBm000005nO9eMAE\' OR Id = \'a0XBm000005nOpVMAU\' OR Id = \'a0XBm000005nOntMAE\'';
                    
                            //\'a0XBm000005nHw5MAE\' OR Id = \'a0XBm000005lisTMAQ\' OR Id = \'a0XBm000005nO9eMAE\' OR Id = \'a0XBm000005nOpVMAU\' OR Id = \'a0XBm000005nOntMAE\''
    
                            /*Dispatch_Date__c <= TODAY and Dispatch_Date__c != null and maica_cc__Dispatch_Status__c != 'Emailed' 
                                             and maica_cc__Dispatch_Status__c != 'Posted' and maica_cc__Dispatch_Status__c != 'Do not dispatch' 
                                             and maica_cc__Dispatch_Status__c != 'Dispatched' and maica_cc__Total_Line_Items__c > 0
                                             and (maica_cc__Status__c = 'Partially Paid' or maica_cc__Status__c = 'Entered')*/
                system.debug('============query============'+query);
            
             return Database.getQueryLocator(query); 
        }
    
//++++++++++++++++++++++++++++++++++++++++Execute Method**************************************************

	global void execute(Database.BatchableContext bc, List<maica_cc__Invoice__c> scope){
		System.debug('========Execute Method=====');
		DocGenerationBatchProcess dgbp = new DocGenerationBatchProcess( Description = 'Generate Invoice', Category = 'Invoice');
		insert dgbp;
        List<maica_cc__Invoice__c> postInvoices = new List<maica_cc__Invoice__c>();
        List<maica_cc__Invoice__c> invoicesToUpdate = new List<maica_cc__Invoice__c>();
        List<DocumentGenerationProcess> dgList = new List<DocumentGenerationProcess>();
        //List<DocumentGenerationProcess> failedDGRecords = new List<DocumentGenerationProcess>();
        Map<DocumentGenerationProcess, String> failedDGRecords = new Map<DocumentGenerationProcess, String>();
        
        for(maica_cc__Invoice__c invoiceRecord : scope){
            System.debug('==========for===');
            System.debug('=====invoiceRecord.maica_cc__Funding_Administrator__r.Billing_Communication_Preference__c===='+invoiceRecord.maica_cc__Funding_Administrator__r.Billing_Communication_Preference__c);
            System.debug('=====invoiceRecord.Id'+invoiceRecord.Id);
           if(invoiceRecord.maica_cc__Funding_Administrator__r.Billing_Communication_Preference__c == 'Email'){
            System.debug('++++++++++Email Invoice Record++++++++');
            System.debug('================scope======'+invoiceRecord.Id);
            String docTemplateName = MC_InvoiceDocumentGenerationClass.getTemplateNameForInvoice(invoiceRecord);
            system.debug('===============docTemplateName============'+docTemplateName);
            List<MC_InvoiceDocumentGenerationClass.DocGenWrapper> docGenWrapList = new List<MC_InvoiceDocumentGenerationClass.DocGenWrapper>();
            MC_InvoiceDocumentGenerationClass.DocGenWrapper docGenWrap = new MC_InvoiceDocumentGenerationClass.DocGenWrapper();
            docGenWrap.recordIds = new List<Id>{invoiceRecord.Id};
            docGenWrap.contentVersionId = templateNameContentDocIdMap.get('Invoice_Template1');//MC_InvoiceDocumentGenerationClass.getContentVersionId(docTemplateName);//Comes from Custommetadata
            docGenWrap.objectApiName = 'maica_cc__Invoice__c';
            docGenWrap.docTemplateName = docTemplateName; //Get Template Name by passing to Method
            //docGenWrap.childSobjName = 'maica_cc__Invoice_Line_Items__c';
            //docGenWrap.childSobjRelFieldName = 'maica_cc__Invoice__c' ;
            docGenWrap.invoiceRecord = invoiceRecord;
            docGenWrap.invoiceLineItems = invoiceRecord.maica_cc__Invoice_Line_Items__r;
            docGenWrap.documentMappingsList = documentMappingsList;
            docGenWrap.documentTemplateId = docTemplateMap.get(docTemplateName);
            docGenWrap.documentgenerationBatchId = dgbp.Id;
            docGenWrap.isMannual = false;
            docGenWrapList.add(docGenWrap);
            DocumentGenerationProcess dgProcess = MC_InvoiceDocumentGenerationClass.generateDocument(docGenWrapList);
        	dgList.add(dgProcess);
        }else if(invoiceRecord.maica_cc__Funding_Administrator__r.Billing_Communication_Preference__c == 'Post') {
             System.debug('++++++++++Post Invoice Record++++++++');    
            	postInvoices.add(invoiceRecord);
            System.debug('postInvoices'+postInvoices.size());
                }
            else{
                System.debug('+++++++++Criteria Does Not match++++++++'); 
            }
        }  
        
		if(!Test.isRunningTest()){
            //insert dgList;
            System.debug('inserting DG');
            Database.SaveResult[] results = Database.insert(dgList, false);
            dgbp.Status = 'Queued';
            update dgbp;
			for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    //failedDGRecords.add(dgList[i]); 
                    String errorMessage = '';
                    for (Database.Error err : results[i].getErrors()) {
                        errorMessage += err.getMessage() + ' ';
                    }
                    failedDGRecords.put(dgList[i], errorMessage.trim());
            	}
        	}
        }
        handleFailedDGs(failedDGRecords);
         System.debug('!!!!!!!!!!!!!!Executing till here!!!!!!!!!!!');
		   if (!postInvoices.isEmpty()) {
            try {
                System.debug('TRY for invoice status to update to POsted');
                csvContent += generateCSV(postInvoices);
                for (maica_cc__Invoice__c inv : postInvoices) {
                    if (inv.maica_cc__Dispatch_Status__c != 'Dispatched') {
                        inv.maica_cc__Dispatch_Status__c = 'Posted';
                        invoicesToUpdate.add(inv);
                        System.debug('Invoice to Update'+invoicesToUpdate.size());
                    }
     				 
                }
                if (!invoicesToUpdate.isEmpty()) {
                     Database.SaveResult[] results = Database.update(invoicesToUpdate, false);
                     system.debug('Database.Save inovice update '+results);
				//update failedInvoices;
				Map<Id, String>  failedPostIds = new Map<Id, String>();
				for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        String errorMessage = '';
        				for (Database.Error err : results[i].getErrors()) {
            				errorMessage += err.getMessage() + ' ';
        				}
                        failedPostIds.put(invoicesToUpdate[i].Id,errorMessage.trim());
                        System.debug('Failed Invoice ID: ' + invoicesToUpdate[i].Id + ' | Error: ' + errorMessage.trim());
                    }
                }
		        MC_GenericExceptionLogger.logExceptions('maica_cc__Invoice__c','Failed to Update Invoice to Posted',failedPostIds,null);
                }
            }catch (Exception e) {
        		System.debug('!!!!!!!!!!!!!executing catch block Postal Errror!!!!!!!!!!!!!!!!!!!!');
                  if (!postInvoices.isEmpty()) {
                      System.debug('postInvoices in Catch block'+postInvoices);
                      for(maica_cc__Invoice__c inv : postInvoices) {
                          inv.maica_cc__Dispatch_Status__c = 'Postal  Error';
                        System.debug('_______uPATE dISPATCH SUCCESSFULLY___________');
                     }
          				Database.update(postInvoices, false);
          	//update postInvoices;
            System.debug('inv to update '+postInvoices);
          	System.debug('UPDATE dISPATCH SUCCESSFULLY '+postInvoices.size());
          	System.debug(e.getMessage());
                    Map<Id, String> failedPostIds = new Map<Id, String>();
                    for(maica_cc__Invoice__c inv : postInvoices) {
                        failedPostIds.put(inv.Id,e.getMessage());
                    }
                    MC_GenericExceptionLogger.logExceptions('maica_cc__Invoice__c','Failed to Send document to Post',failedPostIds,'Post');
        
                  }   
            } 
        }     
    }
 
//++++++++++++++++++++++++++++++++++++++++Finish Method**************************************************
    
    global void finish(Database.BatchableContext bc){
        ////next one hour
        Datetime runTime = System.now().addHours(1); // One hour from now

        String cronExp = runTime.second() + ' ' + runTime.minute() + ' ' + runTime.hour() + ' ' +
                         runTime.day() + ' ' + runTime.month() + ' ? ' + runTime.year();
        
        //next day 12 for retry
        DateTime tomorrowNoon = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(12, 0, 0, 0));
        String cronExp1 = String.format('0 0 12 {0} {1} ? {2}', 
        				new List<String>{
                                String.valueOf(tomorrowNoon.day()),
                                String.valueOf(tomorrowNoon.month()),
                                String.valueOf(tomorrowNoon.year())
                            }
                        );
        if(isRetry == false ) {
           scheduleErrorBatch('Invoice Scheduled Error Job',cronExp, new MC_InvoiceScheduleDocumentError());
           //Schedule job Job at 12 pm
            scheduleSecondBusinessDay('Invoice Job', new MC_InvoiceDocumentGenerationScheduler(),12,0);
            // Schedule OverdueAmount Job at 11 am
			scheduleSecondBusinessDay('Invoice Overdue Amount Job', new MC_InvoiceOverdueAmountUpdateScheduler(),11,0);
           invoiceCount = [SELECT COUNT() FROM maica_cc__Invoice__c WHERE Communication_Preference__c = 'Post' AND maica_cc__Dispatch_Status__c != 'Dispatched'];
            if(String.isNotBlank(csvContent)){
            this.sendEmailForPost();
            }
           scheduleErrorBatch('Invoice Retry Batch',cronExp1, new MC_InvoiceRetryBatchWrapper());
          
           //Job Scheduling for next day
        }
        else {
            // Call Retry Schedule batch
           scheduleErrorBatch('Invoice Scheduled Retry Error Job',cronExp, new MC_InvoiceScheduleRetryError());
            
        }  
    }
    
    //++++++++++++++++++++++++++++++++++++++++Other Methods**************************************************
    
    public static void scheduleErrorBatch(String jobName,String cronExp, Schedulable schedulableInstance) {
        List<CronTrigger> existingJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        for(CronTrigger existjob : existingJobs) {
            System.abortJob(existjob.Id);
        }
        System.schedule(jobName, cronExp, schedulableInstance);
    }    
    private static String formatCurrency(Decimal amount) {
        return amount != null ? '$' + String.valueOf(amount.setScale(2)) : '';
    }
    public static void scheduleSecondBusinessDay(String jobName, Schedulable schedulableInstance, Integer hour, Integer minute) {
        
        // Step 1: Get first day of next month
        Date today = Date.today();
        Integer nextMonth = today.month() == 12 ? 1 : today.month() + 1;
        Integer nextYear = today.month() == 12 ? today.year() + 1 : today.year();
        Date firstDayNextMonth = Date.newInstance(nextYear, nextMonth, 1);

        // Step 2: Get Business Hours ID
        Id bhId = [SELECT Id FROM BusinessHours WHERE Name = 'HomeCare_BusinessHours' LIMIT 1].Id;

        // Step 3: Create DateTime at 12:00 PM
        DateTime dtAtNoon = DateTime.newInstance(firstDayNextMonth, Time.newInstance(12, 0, 0, 0));

        // Step 4: Find first business day
        DateTime firstBusinessDate;
        for (Integer i = 0; i < 20; i++) {
            DateTime dt = dtAtNoon.addDays(i);
            if (BusinessHours.isWithin(bhId, dt)) {
                firstBusinessDate = dt;
                break;
            }
        }

        // Step 5: Find second business day
        DateTime secondBusinessDate;
        for (Integer i = 1; i < 20; i++) {
            DateTime dt = firstBusinessDate.addDays(i);
            if (BusinessHours.isWithin(bhId, dt)) {
                secondBusinessDate = dt;
                break;
            }
        }
        
        //Find seven business days before the second business day
        
        DateTime sevenBusinessDaysBefore;
        Integer businessDayCount = 0;
        
        for (Integer i = 1; i <= 30; i++) {
            DateTime dt = secondBusinessDate.addDays(-i); // Go backwards
            if (BusinessHours.isWithin(bhId, dt)) {
                businessDayCount++;
                if (businessDayCount == 7) {
                    sevenBusinessDaysBefore = dt;
                    break;
                }
            }
        }
         System.debug('++++++++++reminderNotification Starting here++++++++++++++++++');      
            try {
                // Step 1: Get the Public Group by DeveloperName
                Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'AR_Team_PublicGroup' LIMIT 1];
            
                // Step 2: Get all GroupMembers linked to that group
                List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :publicGroup.Id];
            
                // Step 3: Collect only User IDs (exclude nested groups)
                Set<Id> userIds = new Set<Id>();
                for (GroupMember gm : groupMembers) {
                    if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                        userIds.add(gm.UserOrGroupId);
                    }
                }
            
                // Step 4: Query all Users in one SOQL call
                List<User> users = [
                    SELECT Email FROM User WHERE Id IN :userIds AND Email != null
                ];
            
                // Step 5: Use the first email found (if any)
                if (!users.isEmpty()) {
                    String usermail = users[0].Email;
            
                    // Step 6: Insert a single reminder notification
                    MC_Reminder_Notification__c reminderNotification = new MC_Reminder_Notification__c();
                    reminderNotification.Email__c = usermail;
                    reminderNotification.Reminder_Date__c = sevenBusinessDaysBefore;
                    reminderNotification.Invoice_Dispatch_Date__c = secondBusinessDate;
            
                    insert reminderNotification;
            		System.debug('++++++++++reminderNotification'+reminderNotification);
                    System.debug('++++++++Inserted Reminder Record for: ' + usermail);
                    //return;
                } else {
                    System.debug('No valid user emails found in the group.');
                }
            
            } catch (Exception e) {
                System.debug('Error occurred: ' + e.getMessage());
            }
        System.debug('++++++++++reminderNotification closing here++++++++++++++++++');
        
       // Step 6: Set scheduled time using the passed hour/minute
            DateTime scheduledDateTime = DateTime.newInstance(
                secondBusinessDate.date(), 
                Time.newInstance(hour, minute, 0, 0)
            );

           // Step 7: Generate CRON expression
        String cronExp = String.format('0 {0} {1} {2} {3} ? {4}', 
            new List<String>{
                String.valueOf(scheduledDateTime.minute()),
                String.valueOf(scheduledDateTime.hour()),
                String.valueOf(scheduledDateTime.day()),
                String.valueOf(scheduledDateTime.month()),
                String.valueOf(scheduledDateTime.year())
            }
        );
            
        if (!Test.isRunningTest()) {
        System.schedule(jobName + ' - ' + scheduledDateTime.format(), cronExp, schedulableInstance);
    }
}
  	public void sendEmailForPost() {
      
          System.debug('!!!!!!!!!!!!!executing try block Postal Email sent!!!!!!!!!!!!!!!!!!!!');
        String fileName = 'mecwacare_Postal_Invoice' + Datetime.now().format('dd-MM-yyyy_HH:mm') + '.csv';
        String monthYear = DateTime.now().format('MMMM, yyyy');
        String todayDate = Date.today().format();
        String invoiceCountText = invoiceCount != null ? String.valueOf(invoiceCount) : 'N/A';
    
        String recipientEmail;

        // Fetch recipient email from metadata
        if (Test.isRunningTest()) {
            recipientEmail = 'test@test.com';
        } else {
            Environment_Variables__mdt env = [
                SELECT Value__c
                FROM Environment_Variables__mdt
                WHERE DeveloperName = 'Invoice_CSV_mail_to_third_party'
                LIMIT 1];
            recipientEmail = env != null ? env.Value__c : null;
            System.debug('++++++++++++++++++++++++Recipient Email: ' + recipientEmail);
        }
			System.debug('#####recipientEmail ' +recipientEmail);
        	System.debug('#####csvContent ' +csvContent);
        	System.debug('#####fileName ' +fileName);
      
       // if (String.isNotBlank(recipientEmail) && String.isNotBlank(csvContent) && String.isNotBlank(fileName)) {
            // Construct email body
            String emailBody = 'Hi,\n\n' +
                'Please find attached the list of customer invoices for the month of ' + monthYear + '.\n\n' +
                'These invoices are to be printed and mailed to the respective customers as per our standard mailing process.\n\n' +
                'Total Invoices: ' + invoiceCountText + '\n' +
                'Invoice Print Date: ' + todayDate + '\n\n' +
                'If you require any clarification or encounter any discrepancies, please contact us at:\n\n' +
                'Regards,\n' +
                'mecwacare AR Team';
    
            // Prepare attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(fileName);
            attachment.setBody(Blob.valueOf(csvContent));
            attachment.setContentType('text/csv');
    
            // Prepare and send email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { recipientEmail });
            email.setSubject('Customer Invoices for ' + monthYear);
            email.setPlainTextBody(emailBody);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
    
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('#######CSV Scheduled CSV email sent to: ######## ' + recipientEmail);     
	}
    public static void handleFailedDGs(Map<DocumentGenerationProcess, String> failedDGRecords) {
        Map<Id, String> failedInvoiceIds = new Map<Id, String>();
        for (DocumentGenerationProcess dg : failedDGRecords.keySet()) {
            System.debug('Failed Dgs present');
        	if (dg.ReferenceObject != null) {
            	failedInvoiceIds.put((Id)dg.ReferenceObject,failedDGRecords.get(dg));
        	}
    	}
        if (!failedInvoiceIds.isEmpty()) {
            System.debug('Failed DGS');
            List<maica_cc__Invoice__c> failedInvoices = [
                SELECT Id,maica_cc__Dispatch_Status__c from maica_cc__Invoice__c  WHERE Id IN :failedInvoiceIds.keySet()
            ];
            for (maica_cc__Invoice__c inv : failedInvoices) {
                inv.maica_cc__Dispatch_Status__c = 'Document Generation error';
            }
            //update failedInvoices;
            Database.update(failedInvoices, false);
            //Create Exception log Records
            MC_GenericExceptionLogger.logExceptions('maica_cc__Invoice__c','Failed to Generate Document',failedInvoiceIds,'Document');

        }

    }
        private String generateCSV(List<maica_cc__Invoice__c> invoices) {
           //  throw new System.CalloutException('Simulated CSV generation error for testing');
            //Commenting for testing
        
             // Build invoice map
        Map<Id, maica_cc__Invoice__c> invoiceMap = new Map<Id, maica_cc__Invoice__c>();
        for (maica_cc__Invoice__c inv : invoices) {
            invoiceMap.put(inv.Id, inv);
        }

    // Collect all line items
        List<maica_cc__Invoice_Line_Item__c> allLineItems = new List<maica_cc__Invoice_Line_Item__c>();
        for (maica_cc__Invoice__c inv : invoices) {
            if (inv.maica_cc__Invoice_Line_Items__r != null) {
                allLineItems.addAll(inv.maica_cc__Invoice_Line_Items__r);
            }
        }
                // Step 4: Build CSV using single loop
        String header = 'Customer Name,Address,Invoice Date,mecwacare Client ID,Invoice Number,Service Details,Service Type,Units,' +
                        'Rate,Amount(Exc GST) ,GST ,Amount(Inc GST),Total Amount(Exc GST),Total Amount(GST) ,Total Amount (Inc GST),Due By Date,' +
                        'over due amount in the past 30 days,over due amount in the past 60 days,over due amount in the past 90 days,over due amount past 90 days ,Unapplied Payment,Total Balance due,' +
                        'BPAY Biller Code,BPAY Reference,Opted for Direct Debit';
            
        Integer skippedCount = 0;
        String csvBody = '';
        for (maica_cc__Invoice_Line_Item__c line : allLineItems) {
            maica_cc__Invoice__c inv = invoiceMap.get(line.maica_cc__Invoice__c);
            if (inv == null || inv.Communication_Preference__c != 'Post'){ 
            skippedcount++;
                System.debug('+++++++++skippedcount++++++++++++++'+skippedcount);
             continue;
            }
            System.debug('+++++++++++++++++++++++Invoice ID: ' + inv.Id + ', ++++++++++++++++++++++++++Communication Preference: ' + inv.Communication_Preference__c);
    
            String billingAddress = (inv.Account_Name__r.BillingStreet != null ? inv.Account_Name__r.BillingStreet : '') + ', ' + 
                                    (inv.Account_Name__r.BillingCity != null ? inv.Account_Name__r.BillingCity : '') + ', ' +
                                    (inv.Account_Name__r.BillingState != null ? inv.Account_Name__r.BillingState : '')+ ', ' +
                                    (inv.Account_Name__r.BillingPostalCode != null ? inv.Account_Name__r.BillingPostalCode : '');
    
            String baseRow = '"' + inv.Account_Name__r.Name + '","' + billingAddress + '","' + inv.maica_cc__Invoice_Date__c + '","' +
                             inv.Account_Name__r.mecwacare_Client_ID__c + '","' + inv.Invoice_Number__c + '",';
    
            csvBody += baseRow +
                       '"' + line.Service_Detail_Description__c + '","' + line.maica_cc__Support_Item__r.Name + '","' +
                       line.maica_cc__Quantity__c + '","' + formatCurrency(line.maica_cc__Unit_Price__c) + '","' +
                       formatCurrency(line.maica_cc__Amount__c) + '","' + formatCurrency(line.maica_cc__GST_Amount__c) + '","' +
                       formatCurrency(line.maica_cc__Line_Total__c) + '","' + formatCurrency(inv.Total_Amount_Ex_GST__c) + '","' +
                       formatCurrency(inv.Total_GST__c) + '","' + formatCurrency(inv.maica_cc__Total_Amount__c) + '","' +
                       inv.maica_cc__Due_Date__c + '","' +
                       formatCurrency(inv.Account_Name__r.Days_Overdue_1__c) + '","' +
                       formatCurrency(inv.Account_Name__r.Days_Overdue_2__c) + '","' +
                       formatCurrency(inv.Account_Name__r.Days_Overdue_3__c) + '","' +
                       formatCurrency(inv.Account_Name__r.Days_OverDue_4__c) + '","' +
                       formatCurrency(inv.Account_Name__r.Unapplied_Payment__c) + '","' +
                       formatCurrency(inv.Account_Name__r.Balance_Due__c) + '","' +
                       inv.Biller_Code__c + '","' + inv.BPAY_Reference_Number__c + '","' +
                       inv.Account_Name__r.Opted_for_Direct_Debit__c +'"\n';
        }
            return header +'\n'+ csvBody; 
		
        } 
		

}
