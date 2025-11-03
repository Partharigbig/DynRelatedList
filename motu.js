import { LightningElement, track, api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getFocusedTabInfo, getAllTabInfo, openSubtab } from 'lightning/platformWorkspaceApi';
import fetchFormDetails from '@salesforce/apex/MC_GetAllFormData.fetchFormDetails';
import createOrFetchInProgressRecord from '@salesforce/apex/MC_GetAllFormData.createOrFetchInProgressRecord';
import { getWorkspaceApi } from 'lightning/platformWorkspaceApi';
import { getRelatedListsInfo } from 'lightning/uiRelatedListApi';
import getChildRelationshipName from '@salesforce/apex/MC_GetAllFormData.getChildRelationshipName';
import { CurrentPageReference } from 'lightning/navigation';
 
export default class mCAssessmentLaunch extends NavigationMixin(LightningElement) {
    @track objectsData = [];
    @api recordId;
   
    columns = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
    { label: 'Created By', fieldName: 'createdByName', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }
];
 
   
 @wire(getRelatedListsInfo, { parentObjectApiName: 'Account' })
relatedListsInfo;
 
@track selectedCategory = 'All';
@track categoryOptions = [
    { label: 'All', value: 'All' },
    { label: 'Nursing', value: 'Nursing' },
    { label: 'New Service', value: 'new service' },
    { label: 'Allied Health', value: 'Allied health' },
    { label: 'Support at Home', value: 'support at home' },
    { label: 'Health and Safety', value: 'health and safety' },
    { label: 'Community Services', value: 'community services' }
    // Add more categories as needed
];
 
 
handleCategoryChange(event) {
    this.selectedCategory = event.detail.value;
console.log('==selectedCategory===='+this.selectedCategory);
 
    this.fetchData(); // Re-fetch data based on selected category
}
 
 
    connectedCallback() {        
        window.addEventListener('focus', this.handleWindowFocus);
    }
 
    @wire(CurrentPageReference)
        getPageReferenceParameters(currentPageReference) {
            // Check for the recordId in the attributes of the page reference
            if (currentPageReference.attributes && currentPageReference.attributes.recordId) {
                this.recordId = currentPageReference.attributes.recordId;
                console.log('Record ID from CurrentPageReference:', this.recordId);
                // ... use this.recordId here
                if (this.recordId) {
                    console.log('[mCAssessmentLaunch] Fetching data because recordId is available:', this.recordId);
                    this.fetchData();
                } else {
                    console.log('[mCAssessmentLaunch] recordId is not yet available in connectedCallback');
                }
            }
        }
 
    disconnectedCallback() {
        window.removeEventListener('focus', this.handleWindowFocus);
    }
 
    renderedCallback() {
        console.log('[mCAssessmentLaunch] renderedCallback called');
        console.log('[mCAssessmentLaunch] recordId at renderedCallback:', this.recordId);
    }
 
    handleWindowFocus = () => {
        if (this._pendingRefresh) {
            this._pendingRefresh = false;
            this.fetchData();
        }
    };
 
   /* handleNameClick(event) {
        console.log('====entered handleNameclick======');
       
    const recordId = event.target.dataset.id;
    const objectApiName = event.target.dataset.object;
 
    getWorkspaceApi().then(workspaceAPI => {
        console.log('====entered workspace====');
       
        workspaceAPI.openSubtab({
            recordId: recordId,
            url: '/lightning/r/'+objectApiName+'/'+recordId+'/view',
            focus: true
        }).catch(error => {
            console.error('Error opening subtab:', error);
            // Fallback to NavigationMixin
            thisNavigationMixin.Navigate;
        });
    }).catch(error => {
        console.error('Workspace API not available, using NavigationMixin:', error);
        // Fallback to NavigationMixin
        thisNavigationMixin.Navigate;
    });
}
 */
 
    // a=1;
    fetchData() {
    fetchFormDetails({ accountId: this.recordId ,selectedCategory: this.selectedCategory })
        .then(data => {
            // Ensure deep cloning and avoid non-serializable fields
            // console.log(this.a);
            // this.a++;
            console.log('=======category======'+this.selectedCategory);
           console.log('==========data=========='+JSON.stringify(data));
            const cleanData = data.map(obj => {
                console.log('==========obj=========='+JSON.stringify(obj));
                console.log(`Object Label: ${obj.label}, API Name: ${obj.apiName}, RecordTypeId: ${obj.recordTypeId}, Contentdocid: ${obj.contentDocId}`);
               
                const enhancedRecords = obj.records.map(record => {
                    let displayName;
                    if(obj.apiName === 'Custom_Assessment_Form__c'){
                        if(record.RecordType.Name === 'Home Safety Check Part A'){
                            displayName = record.Home_Safety_Check_Part_A_Name__c;
                        }else if(record.RecordType.Name === 'Home Safety Check Part B'){
                            displayName = record.Home_Safety_Check_Part_B_Name__c;
                        }
                    }else{
                        displayName = record.Name;
                    }
                    console.log(`displayName: ${displayName}`);
                console.log(`Record Name: ${record.Name}, Status: ${record.Status__c} `);
                    return {
                        Id: record.Id,
                        Name: displayName,
                        CreatedDate: record.CreatedDate,
                        createdByName: record.CreatedBy?.Name || '',
                        Status__c: record.Status__c || '—',
                        ContentDocId: obj.contentDocId
                    };
                });
 
const hasInProgress = enhancedRecords.some(record => record.Status__c === 'In Progress');
const firstRecordId = enhancedRecords.length > 0 ? enhancedRecords[0].Id : null;
                return {
                    apiName: obj.apiName,
                    label: obj.label,
                    records: enhancedRecords,
                    recordsToDisplay: [...enhancedRecords],
                    sortedBy: null,
                    sortedDirection: null,
                    buttonLabel: hasInProgress ? 'Resume' : 'Start',
                    hideButtonForGdcp : obj.hideButtonForGdcp,
                    firstRecordId,
                    allListApiName: 'All',
                    relationshipName: obj.relationshipName,
                    recordTypeId: obj.recordTypeId || null
                   
                };
            });
           
            this.objectsData = [...cleanData];
            console.log('==========this.objectsData==========='+JSON.stringify(this.objectsData));
        })
        .catch(error => {
            console.error('Error fetching related records:', error);
        });
}
 
navigateToAssessmentRecord(event) {
    console.log('Navigation---------------> Method')
    const objectApiName = event.target.dataset.object;
    const hyperlinkId = event.target.dataset.id;
    console.log(objectApiName + ' ===== objectApiName =====');
    console.log('================hyperlinkId======'+hyperlinkId);
    console.log('===================this.recordId============='+this.recordId);
    //const accountId = this.recordId;
    this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: hyperlinkId,
                        objectApiName: objectApiName,
                        actionName: 'view'
                    }
                });
}
   
handleStartClick(event) {
    const objectApiName = event.target.dataset.object;
    const hyperlinkId = event.target.dataset.id;
    const recordTypeId = event.target.dataset.recordtypeid || null;
    console.log(objectApiName + ' ===== objectApiName =====');
    console.log('================hyperlinkId======'+hyperlinkId);
    console.log('===================this.recordId============='+this.recordId);
    console.log('Record Type ID:', recordTypeId);
    const accountId = this.recordId;
 
    // Fallback to existing logic: create or fetch in-progress record and navigate to it.
            createOrFetchInProgressRecord({ accountId, objectApiName, hyperlinkId, recordTypeId })
            .then(recordId => {
            console.log('Navigating to record:', recordId);
            /*this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: objectApiName,
                    actionName: 'view'
                }
            });*/
           
 
const navigationAttributes = {
                    recordId: recordId,
                    objectApiName: objectApiName,
                    actionName: 'view'
                };
 
                // Include recordTypeId only if it's present
                if (recordTypeId) {
                    navigationAttributes.recordTypeId = recordTypeId;
                }
 
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: navigationAttributes
                        });
 
 
        })
        .catch(error => {
            console.error('Error creating/fetching record:', error);
            if (error && error.body && error.body.message) {
            console.error('Detailed error:', error.body.message);
        }
 
        });
}
 
 
    // --- NEW: View All click handler that triggers the wire adapter ---
handleViewAll(event) {
   
const objectApiName = event.target.dataset.object;
    const recordId = this.recordId;
    const parentObjectApiName = 'Account';
console.log('====objectApiName===='+objectApiName);
console.log('====recordId===='+recordId);
 
    getChildRelationshipName({ childObjectApiName: objectApiName })
        .then(relatedListId => {
            if (relatedListId) {
                console.log('====relatedListId===='+relatedListId);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordRelationshipPage',
                    attributes: {
                        recordId: recordId,
                        objectApiName: parentObjectApiName,
                        relationshipApiName: relatedListId,
                        actionName: 'view',
                    },})}})
 
}      
 
// --- NEW: Open subtab to existing Lightning Component Tab "All2" - FIXED VERSION---
handleOpenDataTableTab(event) {
        // Use currentTarget so we reliably read the dataset from the button, not an inner element
        const childApiName = event && event.currentTarget && event.currentTarget.dataset ? event.currentTarget.dataset.object : null;
        const recordTypeId = event && event.currentTarget && event.currentTarget.dataset ? event.currentTarget.dataset.recordtypeid : null;
        console.log('======childAPiName======'+childApiName);
        console.log('======recordTypeId======'+recordTypeId);
       
        // Create and dispatch the component event (this will be handled by the Aura component)
        // Fixed: Changed event name to match what Aura component is listening for
        const customEvent = new CustomEvent('opensubtab', {
            bubbles: true,
            composed: true,
            detail: { childApiName, recordTypeId }
        });
        console.log('Dispatching event with childApiName:', childApiName);
        console.log('Dispatching event with recordTypeId:', recordTypeId);
        console.log('Event object:', customEvent);
        this.dispatchEvent(customEvent);
        console.log('Event dispatched');
       
        // Add a small delay to ensure event propagation
        setTimeout(() => {
            console.log('Event handling completed');
        }, 100);
}
 
}
 
