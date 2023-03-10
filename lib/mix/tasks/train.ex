#this module puts together our code and function.

defmodule Mix.Tasks.Train do
  use Mix.Task

  @requirements ["app.start"]

  def run(_) do
    EXLA.set_as_nx_default([:tpu, :cuda, :rocm, :hodt])

    {images, labels} = Digits.Model.download()

    images =
      images
      |> Digits.Model.transform_images()
      |> Nx.to_batched_list(32)

    labels =
      labels
      |> Digits.Model.transform_labels()
      |> Nx.to_batched_list(32)


    data = Enum.zip(images, labels)

    training_count_data = floor(0.8 * Enum.count(data))
    validation_count_data = floor(0.2 * training_count_data)

    {training_data, test_data} = Enum.split(data, training_count_data)
    {validation_data, training_data} = Enum.split(training_data, validation_count_data)

    model = Digits.Model.new({1, 28, 28})

    Mix.Shell.IO.info("training...")

    state = Digits.Model.train(model, training_data, validation_data)

    Mix.Shell.IO.info("testing...")

    Digits.Model.test(model, state, test_data)

    Digits.Model.save!(model, state)

    :ok
  end
end
