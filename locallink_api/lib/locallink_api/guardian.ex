# авторизация через JWT (JSON Web Token)

defmodule LocallinkApi.Guardian do
  use Guardian, otp_app: :locallink_api
  alias LocallinkApi.Accounts

  #Создаёт токен на основе ID пользовател
  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  #Извлекает пользователя из токена обратно
  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
