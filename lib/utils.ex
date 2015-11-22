defmodule Utils do
  require Lager
  import Lager
  import Cfg
  import Notification

  alias :ssh, as: SSH
  alias :ssh_sftp, as: SFTP
  alias :timer, as: Timer


  @spec local_file_size(String.t) :: integer
  def local_file_size(file_path) when is_binary(file_path) do
    case File.stat file_path do
      {:ok, file_info} ->
        case file_info do
          %File.Stat{access: _, atime: _, ctime: _, gid: _, inode: _, links: _, major_device: _, minor_device: _, mode: _, mtime: _, size: local_size, type: :regular, uid: _} ->
            local_size

          _ ->
            0
        end

      {:error, err} ->
        error "Error: #{inspect err}."
        0
    end
  end
  def local_file_size(_), do: 0


  @spec size_kib(integer) :: integer
  def size_kib(size_in_bytes) when is_number(size_in_bytes), do: Float.round size_in_bytes / 1024, 2
  def size_kib(_), do: 0


  @spec size_kib(String.t) :: integer
  def file_extension(abs_path) when is_binary(abs_path) do
    if String.contains? abs_path, "." do
      "." <> List.last String.split abs_path, "."
    else
      ""
    end
  end
  def file_extension(_), do: ""


  @doc """
    Example usage:
      remote_file_size :ssh_sftp.read_file_info a_ssh_channel, a_remote_dest_file
  """
  def remote_file_size remote_handle do
    case remote_handle do
      {:ok, remote_file_info} ->
        debug "Remote file info insight: #{inspect remote_file_info}"
        case remote_file_info do
          {:file_info, size, :regular, _, _, _, _, _, _, _, _, _, _, _} ->
            size

          _ ->
            0
        end

      {:error, err} ->
        debug "No remote file. Error: #{inspect err}"
        0
      end
  end


  def stream_file_to_remote channel, handle, local_file, local_size do
    try do
      notice "Streaming file of size: #{size_kib local_size}KiB to remote server.."
      chunks = div local_size, sftp_buffer_size
      debug "Chunks: #{chunks}"
      (File.stream! local_file, [:read], sftp_buffer_size)
        |> Enum.with_index
        |> (Enum.each fn {chunk, index} ->
          chunks_percent = if chunks == 0, do: 100.0, else: index * 100 / chunks
          percent = Float.round chunks_percent, 2
          IO.write "\rProgress: #{percent}% "
          SFTP.write channel, handle, chunk, sftp_write_timeout
        end)
      notification "Uploaded successfully.", :upload
    catch
      x ->
        notification "Error streaming file #{local_file}: #{inspect x}!", :error
    end
  end


  def binary_to_string(content) when is_binary(content) do
    inspect content, binaries: :as_strings
  end


end
