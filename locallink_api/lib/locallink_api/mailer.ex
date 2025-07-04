# заглушка отправки писем (пока не работает)

defmodule LocallinkApi.Mailer do
  @moduledoc """
  Simple mailer stub - email functionality disabled for now
  """

  def deliver(_email) do
    # Email functionality disabled
    {:ok, :delivered}
  end
end
