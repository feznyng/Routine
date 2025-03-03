
#include <mutex>
#include <unordered_set>
#include <vector>

class BlockManager {
public:
	static inline void Init() {
        std::lock_guard lock{ _mutex };
		_appExclusionList.insert(L"C:\\Windows\\explorer.exe");
	}
	static inline void Set(bool a_allow, std::vector<std::string> a_apps, std::vector<std::string> a_dirs) {
		std::lock_guard lock{ _mutex };

		_allow = a_allow;
		_appList.clear();

        for (const auto& app : a_apps) {
            _appList.insert(std::wstring{ app.begin(), app.end() });
        }
	}
	static inline bool IsBlocked(const std::wstring& a_exePath) {
		std::lock_guard lock{ _mutex };
		
		if (_appExclusionList.find(a_exePath) != _appExclusionList.end()) {
			return false;
		}

		bool inList = _appList.find(a_exePath) != _appList.end();

		return ((_allow && !inList) || (!_allow && inList));
	}
private:
	static inline std::mutex _mutex;
	static inline std::unordered_set<std::wstring> _appList;
	static inline std::unordered_set<std::wstring> _appExclusionList;

	static inline bool _allow;
};