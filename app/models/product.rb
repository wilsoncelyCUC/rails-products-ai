class Product < ApplicationRecord
  # This line enables vector similarity search functionality for this model
  # It tells the 'neighbor' gem to use the 'embedding' column for finding similar products
  has_neighbors :embedding

  # This callback automatically runs after a product is created in the database
  # It ensures every product gets its text converted to a vector embedding
  after_create :set_embedding

  private

  # This method converts the product's text information into a numerical vector
  # using OpenAI's embedding model
  def set_embedding
    # Create a new instance of the OpenAI client to access their API
    client = OpenAI::Client.new

    # Send a request to OpenAI's embedding service
    # We're using 'text-embedding-3-small' which converts text to 1536-dimensional vectors
    response = client.embeddings(
      parameters: {
        model: 'text-embedding-3-small',
        # We combine name and description to capture the product's semantic meaning
        input: "Product: #{name}. Description: #{description}, Price: #{price}"
      }
    )

    # Extract the embedding vector from OpenAI's response
    # This is an array of 1536 floating point numbers that represents the product in "vector space"
    embedding = response['data'][0]['embedding']

    # Save the embedding vector back to the database
    # This allows us to later find similar products by calculating vector distances
    update(embedding: embedding)
  end
end
