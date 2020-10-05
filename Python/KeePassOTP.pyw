import json, os, re, requests, winreg
from subprocess import Popen

class plugin():
    def __init__(self, plugin_name, url, author, repo, hive=winreg.HKEY_LOCAL_MACHINE, reg_path=r"SOFTWARE\KeePassPluginUpdater"):
        self.plugin_name = plugin_name
        self.url = url
        self.author = author
        self.repo = repo
        self.hive = hive
        self.reg_path = reg_path

    def get_current_version(self, hive, reg_path, value_name):
        # Connect to registry
        registry = winreg.ConnectRegistry(None, hive)
        # Get key from path with all access
        key = winreg.CreateKeyEx(registry, reg_path, access=983103)

        try:
            # Get value of value_name
            keepassotp = winreg.QueryValueEx(key, value_name)
        except FileNotFoundError:
            # Create if missing
            winreg.SetValueEx(key, value_name, 0, winreg.REG_SZ, "0")
            # Get value of value_name again
            keepassotp = winreg.QueryValueEx(key, value_name)
        except Exception as e:
            # Raise exception for all other errors
            raise
        finally:
            # Get value
            value = winreg.QueryValueEx(key, value_name)[0]
            # Close key
            winreg.CloseKey(key)
        self.current = value

    def get_latest_version(self, url, plugin_name):
        try:
            # Get version data
            resp = requests.get(url)
        except Exception as e:
            raise
        # Set delimiter
        delim = resp.text[0]

        # Split on new line
        for line in resp.text.splitlines():
            # skip first and last line, skip other plugins
            if not line.startswith(delim) and line.split(delim)[0] == plugin_name:
                # Return plugin version
                self.latest = line.split(delim)[1]


    def check_for_updates(self):
        self.get_current_version(self.hive, self.reg_path, self.plugin_name)
        self.get_latest_version(self.url, self.plugin_name)

        if self.current < self.latest:
            return True
        else:
            return False

    def update(self, keepass_folder=r"C:\Program Files (x86)\KeePass Password Safe 2"):
        # KeePass executable
        keepass_exe = f"{keepass_folder}\\KeePass.exe"
        # Stop KeePass
        Popen([keepass_exe, '--exit-all'])
        # Get latest release from Github
        release = json.loads(requests.get(f"https://api.github.com/repos/{self.author}/{self.repo}/releases/latest").text)
        # Download link
        download_link = release['assets'][0]['browser_download_url']
        # Extract filename keep to it the same
        filename =  re.findall(r".+\/(\w+\.plgx)", download_link)[0]
        # Delete old file
        if os.path.isfile(f"{keepass_folder}\\Plugins\\{filename}"):
            os.remove(f"{keepass_folder}\\Plugins\\{filename}")
        # Download plugin file and save it in keepass folder
        file = requests.get(download_link)
        # Write file to disk
        open(f"{keepass_folder}\\Plugins\\{filename}", 'wb').write(file.content)
        # Connect to registry
        registry = winreg.ConnectRegistry(None, self.hive)
        # Get key from path with all access
        key = winreg.CreateKeyEx(registry, self.reg_path, access=983103)
        # Update value in registry
        winreg.SetValueEx(key, self.plugin_name, 0, winreg.REG_SZ, self.latest)
        # Start KeePass again
        Popen([keepass_exe])


keepassotp = plugin(
    'KeePassOTP', # plugin_name
    'https://raw.githubusercontent.com/rookiestyle/keepassotp/master/version.info', # url
    'Rookiestyle', # author
    'KeePassOTP' # repo
    )


if keepassotp.check_for_updates():
    keepassotp.update()
