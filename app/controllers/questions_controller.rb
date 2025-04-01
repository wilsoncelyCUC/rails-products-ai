class QuestionsController < ApplicationController
  def index
    @questions = current_user.questions
    @question = Question.new  # for Form
  end

  def create
    # Load all existing questions for the current user
    # This is needed in case the form validation fails and we need to re-render the index page
    @questions = current_user.questions

    # Initialize new question with params from the form
    @question = Question.new(question_params)

    # Associate the question with the current user
    @question.user = current_user

    if @question.save
      # Handle successful save with different format responses
      respond_to do |format|
        # For Turbo Stream requests (modern Rails/Hotwire way)
        format.turbo_stream do
          # Append the new question to the #questions container in the DOM
          # Uses the _question.html.erb partial to render the new question
          render turbo_stream: turbo_stream.append(
            :questions,                    # Target DOM ID
            partial: "questions/question", # Partial to render
            locals: { question: @question }# Pass the question to the partial
          )
        end

        # For regular HTML requests (fallback for non-Turbo clients)
        format.html { redirect_to question_path }
      end
    else
      # If validation fails, re-render the index page with error messages
      render :index, status: :unprocessable_entity
    end
  end

  private

  def question_params
    # Strong parameters to prevent mass assignment vulnerabilities
    # Only allows the user_question field to be mass-assigned
    params.require(:question).permit(:user_question)
  end

end
