import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
 
export default class ndisClientAlerts extends OmniscriptBaseMixin(LightningElement) {
 
    @api ClientAlert;
    @api maicaAlerts;
    @api clientProfile;
 
    resolvedClientAlerts = '';
 
    connectedCallback() {
        try {
            this.resolveAlerts();
        } catch (e) {
            console.error('Alert Error:', e);
        }
    }
    
    resolveAlerts() {
    
        let alertsArray = [];
    
        const clientName =
            this.clientProfile?.ContactInformation?.Name || '';
    
        const alertsData = this.maicaAlerts;
    
        if (alertsData) {

            if (Array.isArray(alertsData) && alertsData.length > 0) {
    
                alertsData.forEach(alert => {
    
                    let message = alert?.FinalAlertMessage;
    
                    if (message && message.trim() !== '') {
                        alertsArray.push(
                            this.cleanText(message, clientName)
                        );
                    }
                });
            }

            else if (
                !Array.isArray(alertsData) &&
                alertsData?.FinalAlertMessage &&
                alertsData.FinalAlertMessage.trim() !== ''
            ) {
    
                alertsArray.push(
                    this.cleanText(alertsData.FinalAlertMessage, clientName)
                );
            }
        }

        if (alertsArray.length === 0 &&
            this.ClientAlert &&
            this.ClientAlert.trim() !== '') {
    
            let formatted = this.cleanText(this.ClientAlert, clientName);
    
            formatted = formatted.replace(/\. /g, '.\n');
    
            alertsArray.push(formatted);
        }

        this.resolvedClientAlerts = alertsArray
        .map(alert =>
            alert
                .split(/\r\n|\r|\n/)     // split internal lines
                .map(line => '● ' + line.trim())
                .join('\r\n')
        )
        .join('\r\n');

        this.omniApplyCallResp({
            ResolvedClientAlerts: this.resolvedClientAlerts
        });
    }
 
    cleanText(value, clientName) {
   
        if (!value) return '';
   
        let text = value;
   
        text = text.replace(/\{\!\s*Name\s*\}/gi, clientName || '');
 
        text = text.replace(/<\/p>/gi, '\n');
        text = text.replace(/<br\s*\/?>/gi, '\n');
   
        text = text.replace(/<[^>]*>/g, '');

        text = text.replace(/&nbsp;/gi, ' ');
        text = text.replace(/&amp;/gi, '&');
        text = text.replace(/&lt;/gi, '<');
        text = text.replace(/&gt;/gi, '>');
        text = text.replace(/&quot;/gi, '"');

        text = text.replace(/\n\s*\n+/g, '\n\n');
   
        return text.trim();
    }
}
