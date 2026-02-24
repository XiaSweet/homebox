import { Config, SpeedMode, RateUnit, Theme } from './types'

// 获取基础URL，支持从环境变量或HTML base标签获取上下文路径
function getBaseUrl(): string {
    if (process.env.NODE_ENV === 'development') {
        return 'http://localhost:3300';
    }
    
    // 在生产环境中，尝试从HTML的base标签获取路径前缀
    if (typeof document !== 'undefined') {
        const baseTag = document.querySelector('base');
        if (baseTag && baseTag.href) {
            // 移除末尾的斜杠（如果存在）
            const basePath = baseTag.href.replace(/\/$/, '');
            return basePath;
        }
    }
    
    // 默认返回空字符串（相对于当前域名）
    return '';
}

export const BASE_URL = getBaseUrl();
export const CONFIG_STORAGE_KEY = 'homebox:config'

const systemTheme = (() => {
  if (typeof window !== 'undefined' && window.matchMedia) {
    const ret = window.matchMedia('(prefers-color-scheme: dark)')
    if (ret.matches) {
      return Theme.Dark
    }
    return Theme.Light
  }

  return Theme.Light
})()

export const DEFAULT_CONFIG: Config = {
  duration: 10 * 1000,
  threadCount: 1,
  speedMode: SpeedMode.LOW,
  packCount: 64,
  parallel: 3,
  unit: RateUnit.BIT,
  theme: systemTheme,
}