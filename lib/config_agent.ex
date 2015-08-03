defmodule ConfigAgent do
  require Logger

  @name __MODULE__


  def start_link do
    Logger.info "Launching ConfigAgent"
    Agent.start_link fn ->
        %{
          "dmilith" => [
            username: "dmilith",
            hostname: "verknowsys.com",
            ssh_port: 60022,
            address: "http://s.verknowsys.com/",
            remote_path: "/home/dmilith/Web/Public/Sshots/",
            ssh_key_pass: "",
          ],
          "tallica" => [
            username: "michal",
            hostname: "phoebe.tallica.pl",
            ssh_port: 60022,
            address: "http://s.tallica.pl/",
            remote_path: "/Users/michal/Screenshots",
            ssh_key_pass: "",
          ]
        }
      end, name: @name
  end


  def user, do: System.get_env "USER"


  def get key do
    Agent.get @name, fn state ->
      state[user][key]
    end
  end


  # def get_all do
  #   Agent.get @name, fn state ->
  #     state
  #   end
  # end


  # def set key, value do
  #   Agent.update @name, fn state ->
  #     Map.put state, key, value
  #   end
  # end


end
