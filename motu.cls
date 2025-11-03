/**
 * @description       : Apex controller for fetching and managing form records related to an Account.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on  : 10-29-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class MC_GetAllFormData {

    /**
     * Wrapper class to group object metadata and its related records.
     */
    public class ObjectWrapper implements Comparable {
        /**
        * @description 
        * @author ChangeMeIn@UserSettingsUnder.SFDoc | 07-08-2025 
        * @param apiName 
        * @param label 
        * @param records 
        * @return String 
        **/
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public Boolean hideButtonForGdcp;
        @AuraEnabled public string relationshipName;
        @AuraEnabled public Id recordTypeId;
        @AuraEnabled public Id contentDocId;

        public ObjectWrapper(String apiName, String label, List<SObject> records, Boolean hideButtonForGdcp, string relationshipName) {
            this.apiName = apiName;
            this.label = label;
            this.records = records;
            this.hideButtonForGdcp = hideButtonForGdcp;
            this.relationshipName = relationshipName;
        }

        public ObjectWrapper(String apiName, String label, List<SObject> records, Boolean hideButtonForGdcp, Id recordTypeId) {
            this.apiName = apiName;
            this.label = label;
            this.records = records;
            this.hideButtonForGdcp = hideButtonForGdcp;
            this.recordTypeId = recordTypeId;
        }

        // Overload to include ContentDocumentId with relationship name
        public ObjectWrapper(String apiName, String label, List<SObject> records, Boolean hideButtonForGdcp, string relationshipName, Id contentDocId) {
            this.apiName = apiName;
            this.label = label;
            this.records = records;
            this.hideButtonForGdcp = hideButtonForGdcp;
            this.relationshipName = relationshipName;
            this.contentDocId = contentDocId;
        }

        // Overload to include ContentDocumentId with recordTypeId
        public ObjectWrapper(String apiName, String label, List<SObject> records, Boolean hideButtonForGdcp, Id recordTypeId, Id contentDocId) {
            this.apiName = apiName;
            this.label = label;
            this.records = records;
            this.hideButtonForGdcp = hideButtonForGdcp;
            this.recordTypeId = recordTypeId;
            this.contentDocId = contentDocId;
        }

        
    // Sort by label alphabetically (case-insensitive)
        public Integer compareTo(Object other) {
            ObjectWrapper otherWrapper = (ObjectWrapper)other;
            if (this.label == null && otherWrapper.label == null) return 0;
            if (this.label == null) return -1;
            if (otherWrapper.label == null) return 1;
            return this.label.toLowerCase().compareTo(otherWrapper.label.toLowerCase());
        }

    }

    private static final String directCareRole='Direct care team member';


    /**
     * Fetches records for multiple objects related to the given Account ID.
     * Only records with Status__c != 'Completed' are returned.
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectWrapper> fetchFormDetails(String accountId, String selectedCategory) {
        if (String.isBlank(accountId)) {
            throw new AuraHandledException('AccountId is required.');
        }
        try {
            List<ObjectWrapper> result = new List<ObjectWrapper>();
            // Resolve current user's role name once
            String roleName;
            if (UserInfo.getUserRoleId() != null) {
                List<UserRole> ur = [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() LIMIT 1];
                roleName = (ur.isEmpty() ? null : ur[0].Name);
            }
            final String ROLE_NAME = directCareRole;


            System.debug('===selectedCategory=='+selectedCategory);
			System.debug('==roleName=='+roleName+'======'+ROLE_NAME);
            // selectedCategory='Nursing';
            List<mecwa_Assessment_Category_Mapping__mdt> assmentCategoryList;
            if(selectedCategory=='All'){
                assmentCategoryList= [SELECT Id, Category__c, Object_API_Name__c FROM mecwa_Assessment_Category_Mapping__mdt];
            }else{
                 assmentCategoryList= [SELECT Id, Category__c, Object_API_Name__c FROM mecwa_Assessment_Category_Mapping__mdt WHERE Category__c=: selectedCategory];
            }
            System.debug('====assessmentCategoryMetadataQueryList===='+assmentCategoryList);

            Map<String, String> categoryAssmentMap = new Map<String, String>();

            for(mecwa_Assessment_Category_Mapping__mdt mappingRec : assmentCategoryList){
                categoryAssmentMap.put(mappingRec.Object_API_Name__c, mappingRec.Category__c);
            }
            //Print categoryMap
            System.debug('====AssessmentCategoryMap====='+categoryAssmentMap);
            
            //HCP Assessment Form
            if (categoryAssmentMap.containsKey('HCP_Assessment__c') || selectedCategory=='All') {
                if(HCP_Assessment__c.SObjectType.getDescribe().isAccessible()){
                    List<HCP_Assessment__c> HCPForms = [
                        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
                        FROM HCP_Assessment__c
                        WHERE Related_Account__c = :accountId
                        ORDER BY CreatedDate DESC LIMIT 1
                    ];
                    Id hcpContentDocId = null;
                    System.debug('=====ROLE_NAME'+ROLE_NAME);
                    System.debug('=====roleName'+roleName);
                    if (roleName == ROLE_NAME && HCPForms != null && HCPForms.size() > 0 && HCPForms[0].Status__c == 'Completed') {
                        List<ContentDocumentLink> docLinks = [
                            SELECT ContentDocumentId FROM ContentDocumentLink
                            WHERE LinkedEntityId = :HCPForms[0].Id
                            AND ContentDocument.Title LIKE 'HCPAssessment%'
                            LIMIT 1
                        ];
                        hcpContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
   							// Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (HCPForms != null && !HCPForms.isEmpty() && HCPForms[0].Status__c == 'Completed')
							result.add(new ObjectWrapper('HCP_Assessment__c', 'HCP Assessment', HCPForms, true, getChildRelationshipName('HCP_Assessment__c'), hcpContentDocId));
					}
                        
                    }
                    else if(roleName != ROLE_NAME) {
                        result.add(new ObjectWrapper('HCP_Assessment__c', 'HCP Assessment', HCPForms, true, getChildRelationshipName('HCP_Assessment__c')));
                    }
                }
            }
            
      //Pressure Risk Reduction Plan Form
            if (categoryAssmentMap.containsKey('Pressure_Risk_Reduction_Plan__c') || selectedCategory=='All') {
             if(Pressure_Risk_Reduction_Plan__c.SObjectType.getDescribe().isAccessible()){   
    				List<Pressure_Risk_Reduction_Plan__c> PRRPForms = [
        				SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        				FROM Pressure_Risk_Reduction_Plan__c
        				WHERE Related_Account__c = :accountId
        				ORDER BY CreatedDate DESC LIMIT 1
    				];
                    //query content document id if login user is DirectCareWorker AND status of the form is completed
                    Id prrpContentDocId = null;
                    if(roleName == ROLE_NAME && PRRPForms != null && PRRPForms.size() > 0 && PRRPForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId = :PRRPForms[0].Id 
                                                              AND ContentDocument.Title Like 'PressureRiskReductionPlan%' 
                                                              Limit 1 ];
                        prrpContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (PRRPForms != null && !PRRPForms.isEmpty() && PRRPForms[0].Status__c == 'Completed')
    			result.add(new ObjectWrapper('Pressure_Risk_Reduction_Plan__c', 'Pressure Risk Reduction Form', PRRPForms,true,getChildRelationshipName('Pressure_Risk_Reduction_Plan__c'), prrpContentDocId));
            }
          }
					else if(roleName != ROLE_NAME) {
				result.add(new ObjectWrapper('Pressure_Risk_Reduction_Plan__c', 'Pressure Risk Reduction Form', PRRPForms,true,getChildRelationshipName('Pressure_Risk_Reduction_Plan__c'))); 
}
             }
}
        //Nursing Assessment Form
            if (categoryAssmentMap.containsKey('Nursing_Assessment__c') || selectedCategory=='All') {
                if(Nursing_Assessment__c.SObjectType.getDescribe().isAccessible()){
                List<Nursing_Assessment__c> NAFForms = [
                    SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
                    FROM Nursing_Assessment__c
                    WHERE Related_Account__c = :accountId
                    ORDER BY CreatedDate DESC LIMIT 1
   					 ];
                    Id nafContentDocId = null;
                    if(roleName == ROLE_NAME && NAFForms != null && NAFForms.size() > 0 && NAFForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId = :NAFForms[0].Id 
                                                              AND ContentDocument.Title Like 'Nursing%' 
                                                              Limit 1 ];
                        nafContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (NAFForms != null && !NAFForms.isEmpty() && NAFForms[0].Status__c == 'Completed')
    		result.add(new ObjectWrapper('Nursing_Assessment__c', 'Nursing Assessment Form', NAFForms,true,'', nafContentDocId));
            }
          }else if(roleName != ROLE_NAME) {
    		result.add(new ObjectWrapper('Nursing_Assessment__c', 'Nursing Assessment Form', NAFForms,true,''));
}
                }}
        //MEPACS Grampians Report
            if (categoryAssmentMap.containsKey('MEPACS_Grampians_Form__c') || selectedCategory=='All') {
                if(MEPACS_Grampians_Form__c.SObjectType.getDescribe().isAccessible()){
                List<MEPACS_Grampians_Form__c> MGRForms = [
                    SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
                    FROM MEPACS_Grampians_Form__c
                    WHERE Related_Account__c = :accountId
                    ORDER BY CreatedDate DESC LIMIT 1
   					 ];
                    Id mgrContentDocId = null;
                    if(roleName == ROLE_NAME && MGRForms != null && MGRForms.size() > 0 && MGRForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId = :MGRForms[0].Id 
                                                              AND ContentDocument.Title Like 'MEPACS%' 
                                                              Limit 1 ];
                        mgrContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (MGRForms != null && !MGRForms.isEmpty() && MGRForms[0].Status__c == 'Completed')
    		result.add(new ObjectWrapper('MEPACS_Grampians_Form__c', 'MEPACS Grampians Report Form', MGRForms,true,'', mgrContentDocId));
            }
          } else if(roleName != ROLE_NAME) {
    		result.add(new ObjectWrapper('MEPACS_Grampians_Form__c', 'MEPACS Grampians Report Form', MGRForms,true,''));
}       
                }}
       //Home Safety Check Part A Form
             Id recordTypeId2 = Schema.SObjectType.Custom_Assessment_Form__c.getRecordTypeInfosByDeveloperName().get('Home_Safety_Check_Part_A').getRecordTypeId();
            System.debug('recordTypeId2: '+recordTypeId2);
            if (categoryAssmentMap.containsKey('Custom_Assessment_Form__c') || selectedCategory=='All') {
    			List<Custom_Assessment_Form__c> HSCForms = [
        			SELECT Id, Home_Safety_Check_Part_A_Name__c, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c,RecordTypeId,RecordType.Name
        			FROM Custom_Assessment_Form__c
        			WHERE Related_Account__c = :accountId
                    AND RecordTypeId =: recordTypeId2
        			ORDER BY CreatedDate DESC LIMIT 1
    				];
                    Id hscContentDocId = null;
                    if(roleName == ROLE_NAME && HSCForms != null && HSCForms.size() > 0 && HSCForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :HSCForms[0].Id AND ContentDocument.Title Like 'HomeSafetyCheckPartA%' Limit 1];
                        hscContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    }
    		result.add(new ObjectWrapper('Custom_Assessment_Form__c', 'Home Safety Check Part A', HSCForms,true,recordTypeId2, hscContentDocId));
            }
            
      //Home Safety Check Part B Form
            Id recordTypeId = Schema.SObjectType.Custom_Assessment_Form__c.getRecordTypeInfosByDeveloperName().get('Home_Safety_Check_Part_B').getRecordTypeId();
            System.debug('recordTypeId: '+recordTypeId);
            if (categoryAssmentMap.containsKey('Custom_Assessment_Form__c') || selectedCategory=='All') {
    			List<Custom_Assessment_Form__c> HSCBForms = [
        			SELECT Id, Home_Safety_Check_Part_B_Name__c, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c,RecordTypeId,RecordType.Name
        			FROM Custom_Assessment_Form__c
        			WHERE Related_Account__c = :accountId
                    AND RecordTypeId =: recordTypeId
        			ORDER BY CreatedDate DESC LIMIT 1
    				];
                    Id hscbContentDocId = null;
                    if(roleName == ROLE_NAME && HSCBForms != null && HSCBForms.size() > 0 && HSCBForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :HSCBForms[0].Id AND ContentDocument.Title Like 'HomeSafetyCheckPartB%' Limit 1];
                        hscbContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    }
    		result.add(new ObjectWrapper('Custom_Assessment_Form__c', 'Home Safety Check Part B', HSCBForms,true,recordTypeId, hscbContentDocId));
            }
       

            
	//Bed Pole Risk Assessment    
			if (categoryAssmentMap.containsKey('Bed_Pole_Risk_Assessment__c')|| selectedCategory=='All') {
    			if(Bed_Pole_Risk_Assessment__c.SObjectType.getDescribe().isAccessible()){
        			List<Bed_Pole_Risk_Assessment__c> BPRForms = [
            		SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
            		FROM Bed_Pole_Risk_Assessment__c
            		WHERE Related_Account__c = :accountId
            		ORDER BY CreatedDate DESC LIMIT 1
        			];
                    Id bprContentDocId = null;
                    if(roleName == ROLE_NAME && BPRForms != null && BPRForms.size() > 0 && BPRForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :BPRForms[0].Id AND ContentDocument.Title Like 'BedPoleRiskAssessment%' Limit 1];
                        bprContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (BPRForms != null && !BPRForms.isEmpty() && BPRForms[0].Status__c == 'Completed')
        	result.add(new ObjectWrapper('Bed_Pole_Risk_Assessment__c', 'Bed Pole Risk Assessment', BPRForms,true,'', bprContentDocId));
    		}
                }
					else if(roleName != ROLE_NAME) {
        	result.add(new ObjectWrapper('Bed_Pole_Risk_Assessment__c', 'Bed Pole Risk Assessment', BPRForms,true,''));
}
}}
            
	//MINI NUTRITIONAL ASSESSMENT MNA
			if (categoryAssmentMap.containsKey('Mini_Nutritional_Assessment_MNA_form__c')|| selectedCategory=='All') {
    		if(Mini_Nutritional_Assessment_MNA_form__c.SObjectType.getDescribe().isAccessible()){
    			List<Mini_Nutritional_Assessment_MNA_form__c> MNAForms = [
        		SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        		FROM Mini_Nutritional_Assessment_MNA_form__c
        		WHERE Related_Account__c = :accountId
        		ORDER BY CreatedDate DESC LIMIT 1
    			];
                    Id mnaContentDocId = null;
                    if(roleName == ROLE_NAME && MNAForms != null && MNAForms.size() > 0 && MNAForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :MNAForms[0].Id AND ContentDocument.Title Like 'MiniNutritionalAssessment%' Limit 1];
                        mnaContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (MNAForms != null && !MNAForms.isEmpty() && MNAForms[0].Status__c == 'Completed')
    		result.add(new ObjectWrapper('Mini_Nutritional_Assessment_MNA_form__c', 'Mini Nutritional Assessment MNA', MNAForms,true,'', mnaContentDocId));
   				 }
                    }
					else if(roleName != ROLE_NAME) {
    		result.add(new ObjectWrapper('Mini_Nutritional_Assessment_MNA_form__c', 'Mini Nutritional Assessment MNA', MNAForms,true,''));
}
}}
	//Kessler Form
			if (categoryAssmentMap.containsKey('Kessler_Form__c')|| selectedCategory=='All') {
    			if(Kessler_Form__c.SObjectType.getDescribe().isAccessible()){
    				List<Kessler_Form__c> KsdForm = [
        			SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        			FROM Kessler_Form__c
        			WHERE Related_Account__c = :accountId
        			ORDER BY CreatedDate DESC LIMIT 1
    				];
                    Id ksdContentDocId = null;
                    if(roleName == ROLE_NAME && KsdForm != null && KsdForm.size() > 0 && KsdForm[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :KsdForm[0].Id AND ContentDocument.Title Like 'Kessler%' Limit 1];
                        ksdContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (KsdForm != null && !KsdForm.isEmpty() && KsdForm[0].Status__c == 'Completed')
    				result.add(new ObjectWrapper('Kessler_Form__c', 'Kessler Form', KsdForm,true,'', ksdContentDocId));
    				}
                    }else if(roleName != ROLE_NAME) {
    				result.add(new ObjectWrapper('Kessler_Form__c', 'Kessler Form', KsdForm,true,''));
}
}
}

			if (categoryAssmentMap.containsKey('Caregiver_Strain_Index_Form__c')|| selectedCategory=='All') {
                if(Caregiver_Strain_Index_Form__c.SObjectType.getDescribe().isAccessible()){
    				List<Caregiver_Strain_Index_Form__c> csiForms = [
        			SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
       			    FROM Caregiver_Strain_Index_Form__c
        			WHERE Related_Account__c = :accountId
        			ORDER BY CreatedDate DESC LIMIT 1
    				];
                    Id csiContentDocId = null;
                    if(roleName == ROLE_NAME && csiForms != null && csiForms.size() > 0 && csiForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :csiForms[0].Id AND ContentDocument.Title Like 'Caregiver%' Limit 1];
                        csiContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (csiForms != null && !csiForms.isEmpty() && csiForms[0].Status__c == 'Completed')
    		result.add(new ObjectWrapper('Caregiver_Strain_Index_Form__c', 'Caregiver Strain Index', csiForms,true,'', csiContentDocId));
                }
                    }else if(roleName != ROLE_NAME) {
    		result.add(new ObjectWrapper('Caregiver_Strain_Index_Form__c', 'Caregiver Strain Index', csiForms,true,''));
}
}}
            
			if (categoryAssmentMap.containsKey('CAUSEd_Model__c') || selectedCategory=='All') {
                if(CAUSEd_Model__c.SObjectType.getDescribe().isAccessible()){
    				List<CAUSEd_Model__c> causeForms = [
        			SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        			FROM CAUSEd_Model__c
        			WHERE Related_Account__c = :accountId 
        			ORDER BY CreatedDate DESC LIMIT 1
    				];
                    Id causeContentDocId = null;
                    if(roleName == ROLE_NAME && causeForms != null && causeForms.size() > 0 && causeForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :causeForms[0].Id AND ContentDocument.Title Like 'CAUSEd%' Limit 1];
                        causeContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (causeForms != null && !causeForms.isEmpty() && causeForms[0].Status__c == 'Completed')
    			result.add(new ObjectWrapper('CAUSEd_Model__c', 'CAUSEd Model', causeForms,true,'', causeContentDocId));
                }
			}
                else if(roleName != ROLE_NAME) {
    			result.add(new ObjectWrapper('CAUSEd_Model__c', 'CAUSEd Model', causeForms,true,''));
}
}
            }
// if (categoryAssmentMap.containsKey('CAUSEd_Model__c') || selectedCategory=='All') {
//     List<CAUSEd_Model__c> causeForms = [
//         SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c,Related_Assessment__c
//         FROM CAUSEd_Model__c
//         WHERE Related_Account__c = :accountId 
//         ORDER BY CreatedDate DESC LIMIT 1
//     ];
//     result.add(new ObjectWrapper('CAUSEd_Model__c', 'CAUSEd Model', causeForms,true));
// }

		if (categoryAssmentMap.containsKey('Continence_Assessment_Tool_form__c')|| selectedCategory=='All') {
    		if(Continence_Assessment_Tool_form__c.SObjectType.getDescribe().isAccessible()){
    			List<Continence_Assessment_Tool_form__c> catForms = [
        			SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        			FROM Continence_Assessment_Tool_form__c
        			WHERE Related_Account__c = :accountId 
        			ORDER BY CreatedDate DESC LIMIT 1
    				];
                    Id catContentDocId = null;
                    if(roleName == ROLE_NAME && catForms != null && catForms.size() > 0 && catForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :catForms[0].Id AND ContentDocument.Title Like 'Continence%' Limit 1];
                        catContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (catForms != null && !catForms.isEmpty() && catForms[0].Status__c == 'Completed')
    			result.add(new ObjectWrapper('Continence_Assessment_Tool_form__c', 'Continence Assessment Tool', catForms,true,'', catContentDocId));
						}
                    }
				else if(roleName != ROLE_NAME) {
    			result.add(new ObjectWrapper('Continence_Assessment_Tool_form__c', 'Continence Assessment Tool', catForms,true,''));
}
}
        }

			if (categoryAssmentMap.containsKey('ASSIST_Form__c')|| selectedCategory=='All') {
                if(ASSIST_Form__c.SObjectType.getDescribe().isAccessible()){
    				List<ASSIST_Form__c> assistForms = [
        				SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        				FROM ASSIST_Form__c
        				WHERE Related_Account__c = :accountId 
        				ORDER BY CreatedDate DESC LIMIT 1
    					];
                    Id assistContentDocId = null;
                    if(roleName == ROLE_NAME && assistForms != null && assistForms.size() > 0 && assistForms[0].Status__c == 'Completed'){
                        System.debug('===enetered if condition role check completed');
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :assistForms[0].Id AND ContentDocument.Title Like 'ASSIST%' Limit 1];
                        assistContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                        System.debug('contentDocId '+assistContentDocId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (assistForms != null && !assistForms.isEmpty() && assistForms[0].Status__c == 'Completed')
    			result.add(new ObjectWrapper('ASSIST_Form__c', 'ASSIST Form', assistForms,true,'', assistContentDocId));
					}
                    }else if(roleName != ROLE_NAME) {
    			result.add(new ObjectWrapper('ASSIST_Form__c', 'ASSIST Form', assistForms,true,'', assistContentDocId));
}
                }
            }

			if (categoryAssmentMap.containsKey('Braden_Scale_Pressure_Risk_Reduct__c')|| selectedCategory=='All') {
    			if(Braden_Scale_Pressure_Risk_Reduct__c.SObjectType.getDescribe().isAccessible()){
    				List<Braden_Scale_Pressure_Risk_Reduct__c> bspForms = [
       			 		SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        				 FROM Braden_Scale_Pressure_Risk_Reduct__c
        		 		 WHERE Related_Account__c = :accountId 
        				ORDER BY CreatedDate DESC LIMIT 1
    					];
                    Id bspContentDocId = null;
                    if(roleName == ROLE_NAME && bspForms != null && bspForms.size() > 0 && bspForms[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :bspForms[0].Id AND ContentDocument.Title Like 'BSPRiskReduction%' Limit 1];
                        bspContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (bspForms != null && !bspForms.isEmpty() && bspForms[0].Status__c == 'Completed')
    		result.add(new ObjectWrapper('Braden_Scale_Pressure_Risk_Reduct__c', 'BSP Risk Reduction', bspForms,true,'', bspContentDocId));
				}
			}
					else if(roleName != ROLE_NAME) {
    		result.add(new ObjectWrapper('Braden_Scale_Pressure_Risk_Reduct__c', 'BSP Risk Reduction', bspForms,true,''));
}
                }
}
if (categoryAssmentMap.containsKey('DVA_Community_Nursing_Review_Form__c')|| selectedCategory=='All') {
    if(DVA_Community_Nursing_Review_Form__c.SObjectType.getDescribe().isAccessible()){
    		List<DVA_Community_Nursing_Review_Form__c> DVAForms = [
        		SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        		FROM DVA_Community_Nursing_Review_Form__c
        		WHERE Related_Account__c = :accountId 
        		ORDER BY CreatedDate DESC LIMIT 1
    			];
                Id dvaContentDocId = null;
                if(roleName == ROLE_NAME && DVAForms != null && DVAForms.size() > 0 && DVAForms[0].Status__c == 'Completed'){
                    List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :DVAForms[0].Id AND ContentDocument.Title Like 'DVA%' Limit 1];
                    dvaContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (DVAForms != null && !DVAForms.isEmpty() && DVAForms[0].Status__c == 'Completed')
    	result.add(new ObjectWrapper('DVA_Community_Nursing_Review_Form__c','DVA Community Nursing Review',DVAForms,true,'', dvaContentDocId));
			}
                }
					else if(roleName != ROLE_NAME) {
    	result.add(new ObjectWrapper('DVA_Community_Nursing_Review_Form__c','DVA Community Nursing Review',DVAForms,true,''));
}
}
}
if (categoryAssmentMap.containsKey('HACC_Linkage_Service_Request_Form__c')|| selectedCategory=='All') {
    if(HACC_Linkage_Service_Request_Form__c.SObjectType.getDescribe().isAccessible()){
   	 List<HACC_Linkage_Service_Request_Form__c> HACCForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM HACC_Linkage_Service_Request_Form__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id haccContentDocId = null;
    if(roleName == ROLE_NAME && HACCForms != null && HACCForms.size() > 0 && HACCForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :HACCForms[0].Id AND ContentDocument.Title Like 'HACC%' Limit 1];
        haccContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (HACCForms != null && !HACCForms.isEmpty() && HACCForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('HACC_Linkage_Service_Request_Form__c','HACC Linkage Service Request',HACCForms,true,'', haccContentDocId));
	}
}
					else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('HACC_Linkage_Service_Request_Form__c','HACC Linkage Service Request',HACCForms,true,''));
}
    }}
if (categoryAssmentMap.containsKey('Fall_Risk_Older_People__c')|| selectedCategory=='All') {
    if(Fall_Risk_Older_People__c.SObjectType.getDescribe().isAccessible()){
    List<Fall_Risk_Older_People__c> fropForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Fall_Risk_Older_People__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id fropContentDocId = null;
    if(roleName == ROLE_NAME && fropForms != null && fropForms.size() > 0 && fropForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :fropForms[0].Id AND ContentDocument.Title Like 'Fall%' Limit 1];
        fropContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (fropForms != null && !fropForms.isEmpty() && fropForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Fall_Risk_Older_People__c','FROP-COM Form',fropForms,true,'', fropContentDocId));
	}
    }
					else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Fall_Risk_Older_People__c','FROP-COM Form',fropForms,true,''));
}}}

if (categoryAssmentMap.containsKey('FROP_COM_Community_Fall_Risk__c')|| selectedCategory=='All') {
    if(FROP_COM_Community_Fall_Risk__c.SObjectType.getDescribe().isAccessible()){
    List<FROP_COM_Community_Fall_Risk__c> fropComForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM FROP_COM_Community_Fall_Risk__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id fropComContentDocId = null;
    if(roleName == ROLE_NAME && fropComForms != null && fropComForms.size() > 0 && fropComForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :fropComForms[0].Id AND ContentDocument.Title Like 'FROP%' Limit 1];
        fropComContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (fropComForms != null && !fropComForms.isEmpty() && fropComForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('FROP_COM_Community_Fall_Risk__c','FROP-COM Community Fall Risk Screen',fropComForms,true,'', fropComContentDocId));
}
}
					else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('FROP_COM_Community_Fall_Risk__c','FROP-COM Community Fall Risk Screen',fropComForms,true,''));
}
    }}
if (categoryAssmentMap.containsKey('Catheter_Management_Record__c')|| selectedCategory=='All') {
    if(Catheter_Management_Record__c.SObjectType.getDescribe().isAccessible()){
    List<Catheter_Management_Record__c> cmrForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Catheter_Management_Record__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id cmrContentDocId = null;
    if(roleName == ROLE_NAME && cmrForms != null && cmrForms.size() > 0 && cmrForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :cmrForms[0].Id AND ContentDocument.Title Like 'CatheterManagementRecord%' Limit 1];
        cmrContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (cmrForms != null && !cmrForms.isEmpty() && cmrForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Catheter_Management_Record__c','Catheter Management Form',cmrForms,true,'', cmrContentDocId));
                        }
}
					else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Catheter_Management_Record__c','Catheter Management Form',cmrForms,true,''));
}
}
    }
if (categoryAssmentMap.containsKey('Enteral_Feeding_Chart__c')|| selectedCategory=='All') {
    if(Enteral_Feeding_Chart__c.SObjectType.getDescribe().isAccessible()){
    List<Enteral_Feeding_Chart__c> efcForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Enteral_Feeding_Chart__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id efcContentDocId = null;
    if(roleName == ROLE_NAME && efcForms != null && efcForms.size() > 0 && efcForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :efcForms[0].Id AND ContentDocument.Title Like 'EnteralFeeding%' Limit 1];
        efcContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (efcForms != null && !efcForms.isEmpty() && efcForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Enteral_Feeding_Chart__c','Enteral Feeding Chart',efcForms,true,'', efcContentDocId));
    }
    }
					else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Enteral_Feeding_Chart__c','Enteral Feeding Chart',efcForms,true,''));
}
}
    }
if (categoryAssmentMap.containsKey('Diabetes_Treatment_Chart__c')|| selectedCategory=='All') {
    if(Diabetes_Treatment_Chart__c.SObjectType.getDescribe().isAccessible()){
    List<Diabetes_Treatment_Chart__c> bglForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Diabetes_Treatment_Chart__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id bglContentDocId = null;
    if(roleName == ROLE_NAME && bglForms != null && bglForms.size() > 0 && bglForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :bglForms[0].Id AND ContentDocument.Title Like 'DiabetesTreatment%' Limit 1];
        bglContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (bglForms != null && !bglForms.isEmpty() && bglForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Diabetes_Treatment_Chart__c','Diabetes Treatment Chart',bglForms,true,'', bglContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Diabetes_Treatment_Chart__c','Diabetes Treatment Chart',bglForms,true,''));
}
    }}

if (categoryAssmentMap.containsKey('Diabetes_Assessment_Form__c')|| selectedCategory=='All') {
    if(Diabetes_Assessment_Form__c.SObjectType.getDescribe().isAccessible()){
    List<Diabetes_Assessment_Form__c> diabetesForm = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Diabetes_Assessment_Form__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id diabetesContentDocId = null;
    if(roleName == ROLE_NAME && diabetesForm != null && diabetesForm.size() > 0 && diabetesForm[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :diabetesForm[0].Id AND ContentDocument.Title Like 'DiabetesAssessment%' Limit 1];
        diabetesContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (diabetesForm != null && !diabetesForm.isEmpty() && diabetesForm[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Diabetes_Assessment_Form__c','Diabetes Assessment Form',diabetesForm,true,'', diabetesContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Diabetes_Assessment_Form__c','Diabetes Assessment Form',diabetesForm,true,''));
}
    }}
if (categoryAssmentMap.containsKey('Rudas__c')|| selectedCategory=='All') {
    if(Rudas__c.SObjectType.getDescribe().isAccessible()){
    List<Rudas__c> rudasforms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Rudas__c
        WHERE Related_Account__c = :accountId 
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id rudasContentDocId = null;
    if(roleName == ROLE_NAME && rudasforms != null && rudasforms.size() > 0 && rudasforms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :rudasforms[0].Id AND ContentDocument.Title Like 'RUDAS%' Limit 1];
        rudasContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (rudasforms != null && !rudasforms.isEmpty() && rudasforms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Rudas__c','RUDAS Form',rudasforms,true,'', rudasContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Rudas__c','RUDAS Form',rudasforms,true,''));
}
    }}
//  if (categoryAssmentMap.containsKey('Wound_Assessment__c')|| selectedCategory=='All') {
//      if(Wound_Assessment__c.SObjectType.getDescribe().isAccessible()){
//      List<Wound_Assessment__c> woundAssessmentforms = [
//          SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
//          FROM Wound_Assessment__c
//          WHERE Related_Account__c = :accountId 
//          ORDER BY CreatedDate DESC LIMIT 1
//      ];
//     result.add(new ObjectWrapper('Wound_Assessment__c','Wound Assessment',woundAssessmentforms,true));
//      }
//  }
            
if (categoryAssmentMap.containsKey('OHS_Part_C_Risk_Management_Plan__c')|| selectedCategory=='All') {
    if(OHS_Part_C_Risk_Management_Plan__c.SObjectType.getDescribe().isAccessible()){
    List<OHS_Part_C_Risk_Management_Plan__c> OHSForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM OHS_Part_C_Risk_Management_Plan__c
        WHERE Related_Account__c = :accountId
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id ohsContentDocId = null;
    if(roleName == ROLE_NAME && OHSForms != null && OHSForms.size() > 0 && OHSForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :OHSForms[0].Id AND ContentDocument.Title Like 'OHS%' Limit 1];
        ohsContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (OHSForms != null && !OHSForms.isEmpty() && OHSForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('OHS_Part_C_Risk_Management_Plan__c', 'OHS Part C Risk Management Plan', OHSForms,true,'', ohsContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('OHS_Part_C_Risk_Management_Plan__c', 'OHS Part C Risk Management Plan', OHSForms,true,'', ohsContentDocId));
}
    }
}
            
if (categoryAssmentMap.containsKey('Podiatry_Care_Plan_Form__c')|| selectedCategory=='All') {
    if(Podiatry_Care_Plan_Form__c.SObjectType.getDescribe().isAccessible()){
    List<Podiatry_Care_Plan_Form__c> podiatoryForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Podiatry_Care_Plan_Form__c
        WHERE Related_Account__c = :accountId
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id podiatryContentDocId = null;
    if(roleName == ROLE_NAME && podiatoryForms != null && podiatoryForms.size() > 0 && podiatoryForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :podiatoryForms[0].Id AND ContentDocument.Title Like 'Podiatry%' Limit 1];
        podiatryContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (podiatoryForms != null && !podiatoryForms.isEmpty() && podiatoryForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Podiatry_Care_Plan_Form__c', 'Podiatry Care Plan Form', podiatoryForms,true,'', podiatryContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Podiatry_Care_Plan_Form__c', 'Podiatry Care Plan Form', podiatoryForms,true,''));
}
}            
    }
if (categoryAssmentMap.containsKey('Pain_Diary__c')|| selectedCategory=='All') {
    if(Pain_Diary__c.SObjectType.getDescribe().isAccessible()){
    List<Pain_Diary__c> painDairyForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Pain_Diary__c
        WHERE Related_Account__c = :accountId
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id painContentDocId = null;
    if(roleName == ROLE_NAME && painDairyForms != null && painDairyForms.size() > 0 && painDairyForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :painDairyForms[0].Id AND ContentDocument.Title Like 'PainDiary%' Limit 1];
        painContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (painDairyForms != null && !painDairyForms.isEmpty() && painDairyForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Pain_Diary__c', 'Pain Diary', painDairyForms,true,'', painContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Pain_Diary__c', 'Pain Diary', painDairyForms,true,''));
}
}
    }
if (categoryAssmentMap.containsKey('SMMSE_Form__c')|| selectedCategory=='All') {
    if(SMMSE_Form__c.SObjectType.getDescribe().isAccessible()){
    List<SMMSE_Form__c> smmseForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM SMMSE_Form__c
        WHERE Related_Account__c = :accountId
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id smmseContentDocId = null;
    if(roleName == ROLE_NAME && smmseForms != null && smmseForms.size() > 0 && smmseForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :smmseForms[0].Id AND ContentDocument.Title Like 'SMMSE%' Limit 1];
        smmseContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    // Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (smmseForms != null && !smmseForms.isEmpty() && smmseForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('SMMSE_Form__c', 'SMMSE Form', smmseForms,true,'', smmseContentDocId));
    }

    }	else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('SMMSE_Form__c', 'SMMSE Form', smmseForms,true,''));
}
    }  }
            
if (categoryAssmentMap.containsKey('Individual_Support_Plan__c')|| selectedCategory=='All') {
    if(Individual_Support_Plan__c.SObjectType.getDescribe().isAccessible()){
    List<Individual_Support_Plan__c> ispForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM Individual_Support_Plan__c
        WHERE Related_Account__c = :accountId
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id ispContentDocId = null;
    if(roleName == ROLE_NAME && ispForms != null && ispForms.size() > 0 && ispForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :ispForms[0].Id AND ContentDocument.Title Like 'Individial%' Limit 1];
        ispContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    				// Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (ispForms != null && !ispForms.isEmpty() && ispForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('Individual_Support_Plan__c', 'Individial Support Plan Form', ispForms,true,'', ispContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('Individual_Support_Plan__c', 'Individial Support Plan Form', ispForms,true,''));
}
    }  }
//General Observation Form
if (categoryAssmentMap.containsKey('General_Observation_Record__c')|| selectedCategory=='All') {
    if(General_Observation_Record__c.SObjectType.getDescribe().isAccessible()){
    List<General_Observation_Record__c> generalObservationForms = [
        SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
        FROM General_Observation_Record__c
        WHERE Related_Account__c = :accountId
        ORDER BY CreatedDate DESC LIMIT 1
    ];
    Id generalObsContentDocId = null;
    if(roleName == ROLE_NAME && generalObservationForms != null && generalObservationForms.size() > 0 && generalObservationForms[0].Status__c == 'Completed'){
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :generalObservationForms[0].Id AND ContentDocument.Title Like 'General%' Limit 1];
        generalObsContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
    				// Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (generalObservationForms != null && !generalObservationForms.isEmpty() && generalObservationForms[0].Status__c == 'Completed')
    result.add(new ObjectWrapper('General_Observation_Record__c', 'General Observation Form', generalObservationForms,true,'', generalObsContentDocId));
    }
    }else if(roleName != ROLE_NAME) {
    result.add(new ObjectWrapper('General_Observation_Record__c', 'General Observation Form', generalObservationForms,true,''));
}
    } }
    // Goal Directed care Plan
            if (categoryAssmentMap.containsKey('Goal_Directed_Care_Plan_Fom__c')|| selectedCategory=='All') {
                if(Goal_Directed_Care_Plan_Fom__c.SObjectType.getDescribe().isAccessible()){
   					 List<Goal_Directed_Care_Plan_Fom__c> goalDirectedCarePlanForms = [
        			 SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
       				 FROM Goal_Directed_Care_Plan_Fom__c
        			 WHERE Related_Account__c = :accountId
                     ORDER BY CreatedDate DESC LIMIT 1
   				 ];
                        Id goalDirectedContentDocId = null;
                        if(roleName == ROLE_NAME && goalDirectedCarePlanForms != null && goalDirectedCarePlanForms.size() > 0 && goalDirectedCarePlanForms[0].Status__c == 'Completed'){
                            List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId 
                                                                  FROM ContentDocumentLink 
                                                                  WHERE LinkedEntityId = :goalDirectedCarePlanForms[0].Id 
                                                                  AND ContentDocument.Title Like 'GoalDirectedCarePlan%' 
                                                                  Limit 1];
                            goalDirectedContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                        				// Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (goalDirectedCarePlanForms != null && !goalDirectedCarePlanForms.isEmpty() && goalDirectedCarePlanForms[0].Status__c == 'Completed')
    		result.add(new ObjectWrapper('Goal_Directed_Care_Plan_Fom__c', 'Goal Directed Care Plan Form', goalDirectedCarePlanForms,true,'', goalDirectedContentDocId));
                }
                        }else if(roleName != ROLE_NAME) {
    		result.add(new ObjectWrapper('Goal_Directed_Care_Plan_Fom__c', 'Goal Directed Care Plan Form', goalDirectedCarePlanForms,true,''));
}
                        } 
}
            if (categoryAssmentMap.containsKey('Goal_Directed_Care_Plan_Review__c')|| selectedCategory=='All') {
                if(Goal_Directed_Care_Plan_Review__c.SObjectType.getDescribe().isAccessible()){
                List<Goal_Directed_Care_Plan_Fom__c> gdcprecords = [SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
                                                                    FROM Goal_Directed_Care_Plan_Fom__c
                                                                    WHERE Related_Account__c = :accountId
                                                                    ORDER BY CreatedDate DESC LIMIT 1];
                List<Goal_Directed_Care_Plan_Review__c> goalDirectedCarePlanReviewForms = new List<Goal_Directed_Care_Plan_Review__c>();
                if(gdcprecords.isEmpty())
 {// Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (gdcprecords != null && !gdcprecords.isEmpty() && gdcprecords[0].Status__c == 'Completed')
                    result.add(new ObjectWrapper('Goal_Directed_Care_Plan_Review__c', 'Goal Directed Care Plan Review Form', goalDirectedCarePlanReviewForms,false,''));
                        }
 }
		else if(roleName != ROLE_NAME) {
                    result.add(new ObjectWrapper('Goal_Directed_Care_Plan_Review__c', 'Goal Directed Care Plan Review Form', goalDirectedCarePlanReviewForms,false,''));
}
              //  }
                else {
                    goalDirectedCarePlanReviewForms = [SELECT Id, Name, CreatedDate, CreatedById, CreatedBy.Name, Related_Account__c, Status__c
                                                    FROM Goal_Directed_Care_Plan_Review__c
                                                    WHERE Related_Account__c = :accountId
                                                    ORDER BY CreatedDate DESC LIMIT 1];
                    Id gdcpContentDocId = null;
                    if(roleName == ROLE_NAME && gdcprecords != null && gdcprecords.size() > 0 && gdcprecords[0].Status__c == 'Completed'){
                        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :gdcprecords[0].Id AND ContentDocument.Title Like 'GoalDirectedCarePlanReview%' Limit 1];
                        gdcpContentDocId = (docLinks.isEmpty() ? null : docLinks[0].ContentDocumentId);
                    			// Show only completed forms to direct care team members
						if (roleName == ROLE_NAME) {
                            if (gdcprecords != null && !gdcprecords.isEmpty() && gdcprecords[0].Status__c == 'Completed')
                    result.add(new ObjectWrapper('Goal_Directed_Care_Plan_Review__c', 'Goal Directed Care Plan Review Form', goalDirectedCarePlanReviewForms,true,'', gdcpContentDocId));
                   }
                    }
                }}
		} 
            List<ObjectWrapper> finalResult=reorderByRecordPresence(result);
            System.debug('=====resultList===='+result);
            return finalResult;

        } catch (Exception e) {
            // Log exception with stack trace
            logException('fetchFormDetails', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Failed to fetch form details: ' + e.getMessage());
        }
    }
    
    /**
     * Checks for an existing 'In Progress' record for the given object and account.
     * If found, returns it. If the latest is 'Completed', clones it.
     * If no record exists, creates a new one.
     */
    @AuraEnabled
    public static Id createOrFetchInProgressRecord(String accountId, String objectApiName, String hyperLinkId,String recordTypeId) {
        system.debug('==========hyperlinkId======'+hyperLinkId);
        system.debug('=====recordTypeId======'+recordTypeId);
        if (String.isBlank(accountId) || String.isBlank(objectApiName)) {
            throw new AuraHandledException('AccountId and ObjectApiName are required.');
        }

        try {

            if(!String.isBlank(hyperLinkId)){
                return Id.ValueOf(hyperLinkId);
            }
            String query = queryAllFields(accountId, objectApiName,recordTypeId);
            system.debug('================query========'+query);
            List<SObject> latestRecords = Database.query(query);

                if (!latestRecords.isEmpty()) {
                    System.debug('=====latestRecords====='+latestRecords);
                    
                    SObject latest = latestRecords[0];
                    System.debug('===latest==='+latest);
                    
                    String status = (String) latest.get('Status__c');

                    if (status == 'In Progress') {
                        return (Id) latest.get('Id');
                    } 
                    else if (status == 'Completed') {
                        System.debug('===Entered cloning======');
                        
                        
                        // Clone the record and reset status
                        Sobject newRecord;
                        List<Id> IdtoPass = new List<Id>();
                        Map<String,String> mapChildObjVsLookup = new Map<String,String>();
                         IdtoPass.add(latest.Id);
                        if ( objectApiName == 'Catheter_Management_Record__c'){
                            mapChildObjVsLookup.put('CatheterManagementRecordRelatedObject__c','Related_Catheter_Management_Record__c' ) ;
                        newRecord = cloneParentAndChildren(IdtoPass, objectApiName,mapChildObjVsLookup );
                            
                        }
                        
                        else if ( objectApiName == 'Enteral_Feeding_Chart__c'){
                            mapChildObjVsLookup.put('Enteral_Feeding_Record__c','Enteral_Feeding_Chart__c' ) ;
                        newRecord = cloneParentAndChildren(IdtoPass, objectApiName,mapChildObjVsLookup );
                            
                        } else if ( objectApiName == 'Diabetes_Treatment_Chart__c'){
                            mapChildObjVsLookup.put('BGL_Chart_Entries__c','BGL_Charts__c' ) ;
                        newRecord = cloneParentAndChildren(IdtoPass, objectApiName,mapChildObjVsLookup );
                            
                        }
                        
                          else if( objectApiName == 'General_Observation_Record__c'){
                            mapChildObjVsLookup.put('Blood_Pressure__c','General_Observation_Record__c' ) ;
					        mapChildObjVsLookup.put('Pulse__c','General_Observation_Record__c' ) ;
                            mapChildObjVsLookup.put('Other_General_Observation__c','General_Observation_Record__c' ) ;

                        newRecord = cloneParentAndChildren(IdtoPass, objectApiName,mapChildObjVsLookup );
                            
                        }
                        else if ( objectApiName == 'Pain_Diary__c'){
                            mapChildObjVsLookup.put('Pain_Diary_Record__c','Pain_Diary__c' ) ;
                        newRecord = cloneParentAndChildren(IdtoPass, objectApiName,mapChildObjVsLookup );
                            
                        }
                        else if(objectApiName == 'Goal_Directed_Care_Plan_Fom__c') {
                            mapChildObjVsLookup.put('GDCP_Goal__c','Goal_Directed_Care_Plan_Fom__c' );
                            mapChildObjVsLookup.put('GDCP_Action__c','Goal_Directed_Care_Plan_Fom__c' );
                        	newRecord = cloneParentAndChildren(IdtoPass, objectApiName,mapChildObjVsLookup );
                        }
                        // code for no clone of records...
                        else if(objectApiName == 'Goal_Directed_Care_Plan_Review__c') {
                            newRecord = (SObject) Type.forName('Schema.' + objectApiName).newInstance();
                            newRecord.put('Related_Account__c', accountId);
                            newRecord.put('Status__c', 'In Progress');
                            insert newRecord;
                            System.debug('New record created: ' + newRecord.Id);
                            return newRecord.Id;
                        }
                        else{
                           // system.debug('hi there'+IdtoPass);
                        newRecord = cloneParentAndChildren(IdtoPass, objectApiName, null);
                         
                         //newRecord.put('Related_Account__c', accountId);
                         System.debug('====newRecord====='+newRecord);
                         //insert newRecord;
                        }
                        return newRecord.Id;
                    }
                    else{
                        return (Id) latest.get('Id');
                    }
                }
            else{
				
                    
            // No record exists, create a new one
           // SObject newRecord = (SObject) Type.forName('Schema.' + objectApiName).newInstance();
           
SObject newRecord;

Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
if (sObjType == null) {
    throw new AuraHandledException('Invalid object API name: ' + objectApiName);
}

newRecord = sObjType.newSObject(); 
if (!String.isBlank(recordTypeId)) {
    newRecord.put('RecordTypeId', recordTypeId); 
}


            newRecord.put('Related_Account__c', accountId);
            newRecord.put('Status__c', 'In Progress');
            

            insert newRecord;
            System.debug('New record created: ' + newRecord.Id);
            return newRecord.Id;
            }

        } catch (Exception e) {
            System.debug('Error inserting record: ' + e.getMessage());
            logException('createOrFetchInProgressRecord', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Failed to create record: ' + e.getMessage());
        }
    }
    
    
    public static string queryAllFields(Id accountId, String objectName, Id recordTypeId) {
        // Get the describe result for the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();

        // Get all fields
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        List<String> fieldNames = new List<String>();

        for (String fieldName : fieldsMap.keySet()) {
            fieldNames.add(fieldName);
        }

        // Build the SOQL query
        //String soql = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objectName + ' WHERE Related_Account__c = :accountId AND RecordTypeId =:recordTypeId	 ORDER BY CreatedDate DESC LIMIT 1';
		
String soql = 'SELECT ' + String.join(fieldNames, ',') + 
                  ' FROM ' + objectName + 
                  ' WHERE Related_Account__c = :accountId';

    if (!String.isBlank(recordTypeId)) {
        soql += ' AND RecordTypeId = :recordTypeId';
    }

    soql += ' ORDER BY CreatedDate DESC LIMIT 1';

		return soql;
        
    }

    /**
     * Logs exception details to the custom Mecwa_ExceptionLog__c object.
     * 1.param context     - The method or process where the error occurred.
     * 2.param message     - The exception message.
     * 3.param stackTrace  - The full stack trace of the exception.
     */
    private static void logException(String context, String message, String stackTrace) {
        // Replaced DML with System.debug to avoid DML in cacheable/UI contexts
        System.debug('Exception Context: ' + context + ' | Message: ' + message);
        System.debug('StackTrace: ' + stackTrace);
    }

    public static List<ObjectWrapper> reorderByRecordPresence(List<ObjectWrapper> wrappers) {

        List<ObjectWrapper> withRecords = new List<ObjectWrapper>();

        List<ObjectWrapper> withoutRecords = new List<ObjectWrapper>();

        for (ObjectWrapper ow : wrappers) {

            if (ow.records != null && !ow.records.isEmpty()) {

                withRecords.add(ow);

            } else {

                withoutRecords.add(ow);

            }

        }


        
    // Sort both lists alphabetically by name
        withRecords.sort();
        withoutRecords.sort();

        List<ObjectWrapper> orderedResult = new List<ObjectWrapper>();
        
        orderedResult.addAll(withRecords);

        orderedResult.addAll(withoutRecords);

        return orderedResult;

    }

   public static SObject cloneParentAndChildren(List<Id> recordIds,String parentApiName,Map<String, String> childObjectLookupMap)
   {
    // Step 1: Validate object API names
    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    if (!globalDescribe.containsKey(parentApiName)) {
        throw new AuraHandledException('Invalid parent object API name provided.');
    }

    // Step 2: Get all field names for parent object
    Schema.SObjectType parentType = globalDescribe.get(parentApiName);
    Schema.DescribeSObjectResult parentDescribe = parentType.getDescribe();
    List<String> parentFields = new List<String>();

    for (Schema.SObjectField field : parentDescribe.fields.getMap().values()) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        //if (fieldDescribe.isCreateable() && fieldDescribe.isUpdateable() && !fieldDescribe.isCalculated()) {
       // system.debug('=========================='+fieldDescribe.getName());
        //if(fieldDescribe.getName() != 'Related_Assessment__c'){
        	parentFields.add(fieldDescribe.getName());
       // }
        //}
    }

    // Step 3: Query the parent record
    Id parentId = recordIds[0];
    SObject parentRecord = Database.query(
        'SELECT ' + String.join(parentFields, ',') + ' FROM ' + parentApiName + ' WHERE Id = :parentId');

    // Step 4: Clone the parent record
    SObject clonedParent = parentRecord.clone(false, true, false, false);
    //set field values for cloned record
    clonedParent.put('Status__c', 'In Progress');
    //clonedParent.put('Related_Assessment__c', null);
    if (parentDescribe.fields.getMap().containsKey('Related_Assessment__c')) {
        clonedParent.put('Related_Assessment__c', null);
    }

    insert clonedParent;
	System.debug('hi');
    // Step 5: Clone child records for each child object
       
       if(childObjectLookupMap!=null && !childObjectLookupMap.isempty()){
    for (String childApiName : childObjectLookupMap.keySet()) {
        String childLookupField = childObjectLookupMap.get(childApiName);

        if (!globalDescribe.containsKey(childApiName)) {
            continue; // Skip invalid child object
        }

        Schema.SObjectType childType = globalDescribe.get(childApiName);
        Schema.DescribeSObjectResult childDescribe = childType.getDescribe();
        List<String> childFields = new List<String>();

        for (Schema.SObjectField field : childDescribe.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCreateable() && fieldDescribe.isUpdateable() && !fieldDescribe.isCalculated()) {
                childFields.add(fieldDescribe.getName());
            }
        }

        String childQuery = 'SELECT ' + String.join(childFields, ',') + ' FROM ' + childApiName + ' WHERE ' + childLookupField + ' = :parentId';
        List<SObject> childRecords = Database.query(childQuery);

        List<SObject> clonedChildren = new List<SObject>();
        for (SObject child : childRecords) {
            SObject clonedChild = child.clone(false, true, false, false);
            clonedChild.put(childLookupField, clonedParent.get('Id'));
            clonedChildren.add(clonedChild);
        }

        if (!clonedChildren.isEmpty()) {
            insert clonedChildren;
        }
        }
    }

    return clonedParent;
}


    @AuraEnabled(cacheable=true)
    public static String getChildRelationshipName(String childObjectApiName) {
        Schema.SObjectType parentType = Schema.getGlobalDescribe().get('Account');
        if (parentType == null) {
            return null;
        }

        Schema.DescribeSObjectResult parentDescribe = parentType.getDescribe();
        for (Schema.ChildRelationship rel : parentDescribe.getChildRelationships()) {
            if (rel.getChildSObject().getDescribe().getName() == childObjectApiName) {
                return rel.getRelationshipName(); // This is the relatedListId
            }
        }
        return null;
    }
       /**
     * Gets records for a specific object related to an Account
     * Assumes the object has a "Related_Account__c" field
     */
    @AuraEnabled
    public static List<Map<String, Object>> getAccountRelatedRecords(String accountId, String objectApiName, String recordTypeId) {
        if (String.isBlank(accountId) || String.isBlank(objectApiName)) {
            throw new AuraHandledException('AccountId and ObjectApiName are required.');
        }
        System.debug('===accountId===' + accountId + '===' + objectApiName);
        try {
            // Validate object existence and accessibility
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
            if (sObjType == null || !sObjType.getDescribe().isAccessible()) {
                throw new AuraHandledException('Invalid or inaccessible object: ' + objectApiName);
            }

            // Resolve current user's role name once
            String roleName;
            if (UserInfo.getUserRoleId() != null) {
                List<UserRole> ur = [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId() LIMIT 1];
                roleName = (ur.isEmpty() ? null : ur[0].Name);
            }
            final String ROLE_NAME = directCareRole;

            // Ensure typed Id for bind variable (will throw if invalid)
            Id accId = (Id)accountId;

            // Build dynamic query with bind variable to avoid malformed query and injection
            String query =
                'SELECT Id, Name, CreatedDate, Status__c, LastModifiedDate ' +
                'FROM ' + objectApiName +
                ' WHERE Related_Account__c = :accId ';
                
			//	System.debug('===RecordTypeId==='+recordTypeId);

            if (!String.isBlank(recordTypeId)) {
            query += ' AND RecordTypeId = :recordTypeId';
        }

      query += ' ORDER BY CreatedDate DESC';
            
            // Execute the query
            //List<SObject> records = Database.query(query);
            

List<SObject> records;
if (String.isBlank(recordTypeId)) {
    records = Database.query(query);
} else {
    
    records = Database.query(query);
}


            // Convert to list of maps for return
            List<Map<String, Object>> result = new List<Map<String, Object>>();
            
            // Handle ContentDocumentLink for Direct Care Team Member
            Set<Id> completedRecordIds = new Set<Id>();
            if (roleName == ROLE_NAME) {
                for (SObject record : records) {
                    String status = (String) record.get('Status__c');
                    if (status == 'Completed') {
                        completedRecordIds.add((Id) record.get('Id'));
                    }
                }
            }
            
            Map<Id, Id> recordIdToDocId = new Map<Id, Id>();
            if (roleName == ROLE_NAME && !completedRecordIds.isEmpty()) {
                // Query ContentDocumentLink for PDFs without title filter
                String soql = 'SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :completedRecordIds AND ContentDocument.FileExtension = \'PDF\' LIMIT 1000';
                
                List<ContentDocumentLink> docLinks = Database.query(soql);
                for (ContentDocumentLink docLink : docLinks) {
                    recordIdToDocId.put(docLink.LinkedEntityId, docLink.ContentDocumentId);
                }
            }

           for (SObject record : records) {
    Map<String, Object> recordMap = new Map<String, Object>();

    Id recordId      = (Id) record.get('Id');
    String name      = (String) record.get('Name');
    DateTime created = (DateTime) record.get('CreatedDate');
    DateTime modified= (DateTime) record.get('LastModifiedDate');
    String status    = (String) record.get('Status__c');

    // Format to dd/MM/yyyy. Null-safe checks.
    String createdDateFormatted      = (created != null)  ? created.format('dd/MM/yyyy')       : null;
    String lastModifiedDateFormatted = (modified != null) ? modified.format('dd/MM/yyyy')      : null;

    recordMap.put('id', recordId);
    recordMap.put('name', name);
    recordMap.put('status__c', status);

    // Preserve raw values if you still need them (optional)
    recordMap.put('createdDate', created);
    recordMap.put('lastModifiedDate', modified);

    // Add formatted string fields for LWC UI
    recordMap.put('createdDateFormatted', createdDateFormatted);
    recordMap.put('lastModifiedDateFormatted', lastModifiedDateFormatted);

    recordMap.put('contentDocId', recordIdToDocId.get(recordId));
    result.add(recordMap);
}

            return result;
        } catch (Exception e) {
            logException('getAccountRelatedRecords', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Failed to fetch records: ' + e.getMessage());
        }
    }
    
}
