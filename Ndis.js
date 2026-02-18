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
 
        // Correct JSON path you confirmed
        const clientName =
            this.clientProfile?.ContactInformation?.Name || '';
 
        // ==================================================
        // PRIORITY 1 → maicaAlerts (ONLY FinalAlertMessage)
        // ==================================================
        if (Array.isArray(this.maicaAlerts) && this.maicaAlerts.length > 0) {
 
            this.maicaAlerts.forEach(alert => {
 
                let message = alert?.FinalAlertMessage;
 
                if (message && message.trim() !== '') {
                    alertsArray.push(
                        this.cleanText(message, clientName)
                    );
                }
            });
        }
 
        // ==================================================
        // PRIORITY 2 → ClientAlert (if maicaAlerts empty)
        // ==================================================
        else if (this.ClientAlert && this.ClientAlert.trim() !== '') {
 
            let formatted = this.cleanText(this.ClientAlert, clientName);
 
            // Break sentences to match maicaAlerts visual format
            formatted = formatted.replace(/\. /g, '.\n');
 
            alertsArray.push(formatted);
        }
 
        // Join uniformly
        this.resolvedClientAlerts = alertsArray.join('\r\n');
 
        // Send back to OmniScript JSON
        this.omniApplyCallResp({
            ResolvedClientAlerts: this.resolvedClientAlerts
        });
    }
 
    cleanText(value, clientName) {
   
        if (!value) return '';
   
        let text = value;
   
        // Replace merge field safely
        text = text.replace(/\{\!\s*Name\s*\}/gi, clientName || '');
   
        // Convert paragraph tags to line breaks BEFORE removing HTML
        text = text.replace(/<\/p>/gi, '\n');
        text = text.replace(/<br\s*\/?>/gi, '\n');
   
        // Remove all remaining HTML tags
        text = text.replace(/<[^>]*>/g, '');
   
        // Decode common HTML entities
        text = text.replace(/&nbsp;/gi, ' ');
        text = text.replace(/&amp;/gi, '&');
        text = text.replace(/&lt;/gi, '<');
        text = text.replace(/&gt;/gi, '>');
        text = text.replace(/&quot;/gi, '"');
   
        // Normalize multiple line breaks (but KEEP them)
        text = text.replace(/\n\s*\n+/g, '\n\n');
   
        return text.trim();
    }
}
