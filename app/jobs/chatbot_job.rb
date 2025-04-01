# app/jobs/chatbot_job.rb
class ChatbotJob < ApplicationJob
  # Set default queue for background processing
  queue_as :default

  def perform(question)
    # Store question object for use throughout the job
    @question = question

    # Make API call to ChatGPT
    chatgpt_response = client.chat(
      parameters: {
        #model: "gpt-3.5-turbo",  # Specify which GPT model to use
        model: "gpt-4o-mini",  # Specify which GPT model to use
        messages: questions_formatted_for_openai  # Format message history for API
      }
    )

    # Extract the AI's response from the API response
    new_content = chatgpt_response["choices"][0]["message"]["content"]

    # Update the question record with AI's answer
    question.update(ai_answer: new_content)

    # Broadcast the update to all subscribers using Turbo Streams
    # This will automatically update the chat interface for all users
    Turbo::StreamsChannel.broadcast_update_to(
      "question_#{@question.id}",         # Channel name
      target: "question_#{@question.id}", # DOM element to update
      partial: "questions/question",      # Partial to render
      locals: { question: question }      # Data to pass to partial
    )
    #  Flow of what happens:------
    #1) User submits a question → shows with "..." for ai_answer
    #2) ChatbotJob processes in background and gets AI response
    #3) When AI responds, ChatbotJob updates the question.ai_answer in database
    #4) The broadcast sends this update to all subscribed clients
    #5) Turbo receives the broadcast and updates just the matching div with new content
    #6) The "..." gets replaced with the actual AI answer automatically
  end

  private

  # Memoized OpenAI client instance
  # Creates client only once and reuses it for subsequent calls
  def client
    @client ||= OpenAI::Client.new
  end

  def questions_formatted_for_openai
    # Initialize array to store formatted messages
    results = []

    # Make the system message more strict and explicit
    system_text = "You are a product information assistant. STRICT RULES:
    1. ONLY provide information about the specific products listed below
    2. When asked about prices, ONLY state the exact price from the product data
    3. DO NOT provide general price ranges or information about products not listed
    4. DO NOT make assumptions or generalizations
    5. If the exact product is found, respond with: 'Yes, we have [Product Name] for $[Exact Price]. [Description]'
    6. If the exact product is not found, respond with: 'I apologize, but I can only provide information about specific products in our inventory, and I don't see that exact item listed.'

    Available Products:\n"

    nearest_products = get_nearest_products

    # Format product information more clearly
    nearest_products.each do |product|
      system_text += """
      PRODUCT ID: #{product.id}
      NAME: #{product.name}
      DESCRIPTION: #{product.description}
      PRICE: $#{product.price}
      ----------------------
      """
    end

    # Add the system message first
    results << {
      role: "system",
      content: system_text
    }

    # Add conversation history
    @question.user.questions.each do |question|
      results << {
        role: "user",
        content: question.user_question
      }
      if question.ai_answer.present?
        results << {
          role: "assistant",
          content: question.ai_answer
        }
      end
    end

    Rails.logger.info "=== System Message ==="
    Rails.logger.info system_text
    Rails.logger.info "=== End System Message ==="

    return results
  end

  def get_nearest_products
    begin
      Rails.logger.info "=== Starting Product Search ==="
      Rails.logger.info "Question: #{@question.user_question}"

      # Convert the question to a Vector
      response = client.embeddings(
        parameters: {
          model: 'text-embedding-3-small',
          input: @question.user_question
        }
      )
      question_embedding = response['data'][0]['embedding']

      # Perform vector similarity search with distance logging
      vector_results = Product.nearest_neighbors(
        :embedding,
        question_embedding,
        distance: "euclidean"
      ).first(5)

      Rails.logger.info "=== Vector Search Results ==="
      vector_results.each do |product|
        Rails.logger.info "Vector match: #{product.name}"
        Rails.logger.info "  Description: #{product.description}"
        Rails.logger.info "  Price: $#{product.price}"
      end

      # Perform keyword search for "bluejeans" or "trousers" specifically
      keyword_results = Product.where(
        "LOWER(name) LIKE :search OR LOWER(description) LIKE :search",
        search: "%bluejeans%"
      ).or(
        Product.where(
          "LOWER(name) LIKE :search OR LOWER(description) LIKE :search",
          search: "%trousers%"
        )
      ).limit(5)

      Rails.logger.info "=== Keyword Search Results ==="
      keyword_results.each do |product|
        Rails.logger.info "Keyword match: #{product.name}"
        Rails.logger.info "  Description: #{product.description}"
        Rails.logger.info "  Price: $#{product.price}"
      end

      # Combine results with priority for keyword matches
      combined_results = (keyword_results + vector_results).uniq

      Rails.logger.info "=== Final Combined Results ==="
      combined_results.each do |product|
        Rails.logger.info "Final result: #{product.name}"
        Rails.logger.info "  Description: #{product.description}"
        Rails.logger.info "  Price: $#{product.price}"
      end

      combined_results.first(5) || []
    rescue => e
      Rails.logger.error "Error in get_nearest_products: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      []
    end
  end

#   def get_nearest_products
#     # Convert the question to a Vector
#     response = client.embeddings(
#       parameters: {
#         model: 'text-embedding-3-small',
#         input: @question.user_question
#       }
#     )
#     question_embedding = response['data'][0]['embedding']

#     #2 Find the nearest neightbor product embedding to my question
#     return Product.nearest_neighbors(
#       :embedding, question_embedding, #looking at the column embedding on the product model
#       distance: "euclidean"
#     ).first(3)# you may want to add .first(3) here to limit the number of results
#   end
end
