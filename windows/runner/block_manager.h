
#include <mutex>
#include <unordered_set>
#include <unordered_map>
#include <vector>

class BlockManager {
public:
	static inline void Set(bool a_allow, const std::vector<std::string>& a_apps, const std::vector<std::string>& a_dirs) {
		std::lock_guard lock{ _mutex };

		_allow = a_allow;
    
        _cache.clear();
        _cache.insert({ L"C:\\Windows\\explorer.exe", false });

        WCHAR path[MAX_PATH];
        GetModuleFileNameW(NULL, path, MAX_PATH);

        _cache.insert({ std::wstring{ path }, false });

		_appList.clear();
        for (const auto& app : a_apps) {
            _appList.insert(std::wstring{ app.begin(), app.end() });
        }

        _dirList.clear();

        if (a_allow) {
            _dirList.emplace_back(std::wstring{ L"C:\\Windows\\SystemApps" });
        }
        
        for (const auto& dir : a_dirs) {
            _dirList.emplace_back(std::wstring{ dir.begin(), dir.end() });
        }
	}
	static inline bool IsBlocked(const std::wstring& a_exePath) {
		std::lock_guard lock{ _mutex };
		
        const auto& inCacheList = _cache.find(a_exePath);
        if (inCacheList != _cache.end()) {
            return inCacheList->second;
        }

		const bool inList = _appList.find(a_exePath) != _appList.end() || InDirectories(a_exePath);
        const bool res = (!_allow && inList) || (_allow && !inList);

		_cache[a_exePath] = res;

		return res;
	}
private:
    static inline bool InDirectories(const std::wstring& a_dir) {
		for (const auto& dir : _dirList) {
			if (a_dir.find(dir) != std::wstring::npos) {
				return true;
			}
		}

        return false;
    }

	static inline std::mutex _mutex;
	static inline std::unordered_set<std::wstring> _appList;
    static inline std::vector<std::wstring> _dirList;

    static inline std::unordered_map<std::wstring, bool> _cache;

	static inline bool _allow;
};