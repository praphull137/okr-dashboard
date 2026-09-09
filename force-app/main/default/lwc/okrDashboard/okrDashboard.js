import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getObjectives from '@salesforce/apex/ObjectiveController.getObjectives';
import getKeyResults from '@salesforce/apex/ObjectiveController.getKeyResults';

export default class OkrDashboard extends LightningElement {

    showObjectiveForm = false;
    showKeyResultForm = false;
    showSurveyForm = false;
    showReviewForm = false;
    showGoogleReviewForm = false;
    showCaseStudyForm = false;

    objectives = [];
    isLoading = true;

    @wire(getObjectives)
    wiredObjectives({ data, error }) {

        if (data) {

            this.objectives = data.map(objective => {
                return {
                    ...objective,
                    keyResults: []
                };
            });

            this.loadKeyResults();

            this.isLoading = false;

        } else if (error) {

            this.isLoading = false;

            console.error('Error loading Objectives:', error);

            this.showToast(
                'Error',
                'There was a problem loading Objectives.',
                'error'
            );
        }
    }

    async loadKeyResults() {

        try {

            const updatedObjectives = [];

            for (const objective of this.objectives) {

                const keyResults =
                    await getKeyResults({
                        objectiveId: objective.Id
                    });

                updatedObjectives.push({
                    ...objective,
                    keyResults: keyResults
                });
            }

            this.objectives = updatedObjectives;

        } catch (error) {

            console.error('Error loading Key Results:', error);

            this.showToast(
                'Error',
                'There was a problem loading Key Results.',
                'error'
            );
        }
    }

    handleNewObjective() {
        this.closeAllForms();
        this.showObjectiveForm = true;
    }

    handleNewKeyResult() {
        this.closeAllForms();
        this.showKeyResultForm = true;
    }

    handleNewSurvey() {
        this.closeAllForms();
        this.showSurveyForm = true;
    }

    handleNewReview() {
        this.closeAllForms();
        this.showReviewForm = true;
    }

    handleNewGoogleReview() {
        this.closeAllForms();
        this.showGoogleReviewForm = true;
    }

    handleNewCaseStudy() {
        this.closeAllForms();
        this.showCaseStudyForm = true;
    }

    handleCancel() {
        this.closeAllForms();
    }

    closeAllForms() {
        this.showObjectiveForm = false;
        this.showKeyResultForm = false;
        this.showSurveyForm = false;
        this.showReviewForm = false;
        this.showGoogleReviewForm = false;
        this.showCaseStudyForm = false;
    }

    handleObjectiveSuccess() {

        this.showObjectiveForm = false;

        this.showToast(
            'Success',
            'Objective created successfully.',
            'success'
        );

        window.location.reload();
    }

    handleKeyResultSuccess() {

        this.showKeyResultForm = false;

        this.showToast(
            'Success',
            'Key Result created successfully.',
            'success'
        );

        window.location.reload();
    }

    handleSurveySuccess() {

        this.showSurveyForm = false;

        this.showToast(
            'Success',
            'Survey created successfully.',
            'success'
        );

        window.location.reload();
    }

    handleReviewSuccess() {

        this.showReviewForm = false;

        this.showToast(
            'Success',
            'Review created successfully.',
            'success'
        );

        window.location.reload();
    }

    handleGoogleReviewSuccess() {

        this.showGoogleReviewForm = false;

        this.showToast(
            'Success',
            'Google Review created successfully.',
            'success'
        );

        window.location.reload();
    }

    handleCaseStudySuccess() {

        this.showCaseStudyForm = false;

        this.showToast(
            'Success',
            'Case Study created successfully.',
            'success'
        );

        window.location.reload();
    }

    handleError(event) {

        console.error('Error saving record:', event.detail);

        this.showToast(
            'Error',
            'There was a problem saving the record.',
            'error'
        );
    }

    showToast(title, message, variant) {

        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });

        this.dispatchEvent(toastEvent);
    }
}