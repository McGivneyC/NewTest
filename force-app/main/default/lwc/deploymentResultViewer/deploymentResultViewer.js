import { LightningElement, api, wire, track } from 'lwc';
import getDeploymentResultJson from '@salesforce/apex/DeploymentResultController.getDeploymentResultJson';

export default class DeploymentResultViewer extends LightningElement {
    @api recordId;
    @track isLoading = true;
    @track hasError = false;
    @track hasResult = false;
    @track errorMessage = '';
    @track deploymentStatus = '';
    @track numberComponentsDeployed = 0;
    @track numberComponentsTotal = 0;
    @track numberComponentErrors = 0;
    @track completedDate = '';
    @track numTestsRun = 0;
    @track numFailures = 0;
    @track componentRows = [];

    @wire(getDeploymentResultJson, { recordId: '$recordId' })
    wiredResult({ error, data }) {
        this.isLoading = false;
        if (data) {
            try {
                this.parseResult(data);
                this.hasResult = true;
            } catch (e) {
                this.hasError = true;
                this.errorMessage = 'Failed to parse deployment result JSON: ' + e.message;
            }
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body ? error.body.message : 'Unknown error retrieving deployment result.';
        }
    }

    parseResult(jsonString) {
        const parsed = JSON.parse(jsonString);
        const result = parsed.result || parsed;
        this.deploymentStatus = result.status || 'Unknown';
        this.numberComponentsDeployed = result.numberComponentsDeployed || 0;
        this.numberComponentsTotal = result.numberComponentsTotal || 0;
        this.numberComponentErrors = result.numberComponentErrors || 0;
        this.completedDate = result.completedDate
            ? new Date(result.completedDate).toLocaleString()
            : 'N/A';
        const testResult = (result.details && result.details.runTestResult) || {};
        this.numTestsRun = testResult.numTestsRun || 0;
        this.numFailures = testResult.numFailures || 0;
        const successes = (result.details && result.details.componentSuccesses) || [];
        const files = result.files || [];
        const stateMap = {};
        files.forEach(f => {
            if (!stateMap[f.fullName]) {
                stateMap[f.fullName] = f.state;
            }
        });
        this.componentRows = successes
            .filter(c => c.componentType)
            .map(c => ({
                fullName: c.fullName,
                componentType: c.componentType,
                state: stateMap[c.fullName] || (c.created ? 'Created' : c.changed ? 'Changed' : 'Unchanged'),
                statusLabel: c.success ? 'Success' : 'Failed',
                statusIcon: c.success ? 'utility:success' : 'utility:error',
                statusVariant: c.success ? 'success' : 'error'
            }));
    }

    get hasComponents() {
        return this.componentRows && this.componentRows.length > 0;
    }

    get statusBadgeClass() {
        const base = 'status-badge ';
        if (this.deploymentStatus === 'Succeeded') return base + 'status-success';
        if (this.deploymentStatus === 'Failed') return base + 'status-error';
        return base + 'status-neutral';
    }

    get errorCountClass() {
        return this.numberComponentErrors > 0 ? 'summary-value summary-error' : 'summary-value';
    }
}