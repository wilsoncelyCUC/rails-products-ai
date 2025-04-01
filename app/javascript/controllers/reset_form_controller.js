// app/javascript/controllers/reset_form_controller.js

import { Controller } from "@hotwired/stimulus"

// Workflow:
// 1. User types question in form
// 2. User clicks "Ask" button
// 3. Form submits via Turbo (no page reload)
// 4. Question appears in chat with "..." for AI answer
// 5. ChatbotJob processes in background:
//    - Calls OpenAI API
//    - Gets response
//    - Updates question record
//    - Broadcasts update
// 6. Turbo Stream updates the question bubble with AI answer
// 7. This controller resets form (clears input)
// 8. User can ask next question

// Controller connects to: <form data-controller="reset-form">
export default class extends Controller {
 // Called after successful form submission
 // Triggered by: data-action="turbo:submit-end->reset-form#reset"
 reset() {
   // Clear all form inputs to their default state
   // In this case, clears the question text input
   this.element.reset()

   // At this point:
   // - Question is saved in database
   // - New question bubble is added to chat
   // - ChatbotJob is processing in background
   // - Form is ready for next question
 }
}
