# Layout Editor Web SDK（iframe 通信）

这个 SDK 由 Flutter Web 侧注入到 `window.layoutEditor`，用于父页面与 iframe 内嵌的布局编辑器进行双向通信（调用方法 + `postMessage` 协议）。

## 0. 给总控后台（后端/前端）的接入要点

- 把“编辑器页面”以 iframe 方式嵌入总控后台，并在父页面用 `postMessage` 与 iframe 通信
- 建议把编辑器单独部署成一个静态站点（独立域名/路径），总控后台通过 iframe 引用它
- 生产环境必须做 origin 白名单：父页面校验 `event.origin`，Flutter 侧配置 `allowedOrigins` 与 `targetOrigin`

### 0.1 Flutter 侧如何配置允许的父页面 origin

Flutter Web 内部初始化 SDK 的位置在 [layout_manager_page.dart](file:///Users/lin/Desktop/-/flutter_virtual_keyboard/example/lib/views/layout_manager_page.dart) 里 `initWebInterop(...)`。

你们需要在“编辑器站点”构建/部署时确定总控后台 origin，并在初始化时传入：

- `allowedOrigins: ['https://admin.example.com']`
- `targetOrigin: 'https://admin.example.com'`

如果希望通过构建参数注入（推荐），可使用 `--dart-define`，并在 Flutter 侧用 `String.fromEnvironment(...)` 读取后传给 `initWebInterop(...)`。

## 1. 快速开始（父页面）

父页面把编辑器以 iframe 方式嵌入：

```html
<iframe id="layout-editor" src="https://your-host/editor/" style="width:100%;height:800px;"></iframe>
```

监听来自 iframe 的事件（SDK 就绪 / 布局切换）：

```js
const iframe = document.getElementById('layout-editor');
const editorWin = () => iframe.contentWindow;

window.addEventListener('message', (e) => {
  if (e.source !== editorWin()) return;
  if (e.origin !== 'https://your-host') return;
  const msg = e.data;
  if (!msg || msg.channel !== 'layout_editor') return;

  if (msg.type === 'sdk_ready') {
    console.log('SDK ready:', msg.data);
  }
  if (msg.type === 'layout_changed') {
    console.log('Layout changed:', msg.data);
  }
});
```

父页面向 iframe 发送命令时，必须指定正确的 `targetOrigin`（不要用 `'*'`）：

```js
iframe.contentWindow.postMessage(
  { channel: 'layout_editor', type: 'list_layouts', requestId: crypto.randomUUID() },
  'https://your-host'
);
```

## 2. window.layoutEditor 全局对象（iframe 内部）

iframe 内部（Flutter Web）会挂载：

- `window.layoutEditor.version: string`
- `window.layoutEditor.channel: string`（默认 `layout_editor`）
- `window.layoutEditor.exportLayout(): string`  
  返回当前布局 JSON（同步；如果你的 Flutter 侧使用缓存策略，可能返回最近一次刷新后的值）
- `window.layoutEditor.importLayout(json: string): void`
- `window.layoutEditor.listLayouts(): Array<{id: string, name: string}>`
- `window.layoutEditor.selectLayout(id: string): void`
- `window.layoutEditor.toggleEdit(): void`

父页面如果能直接拿到 iframe 的 `contentWindow`，也可以直接调用这些方法进行调试：

```js
document.getElementById('layout-editor').contentWindow.layoutEditor.listLayouts()
```

## 3. postMessage 协议（推荐）

为了解耦“父页面跨域 / 不能直接调用 iframe window”的场景，SDK 同时支持 `postMessage` 请求-响应。

### 3.1 消息包格式

统一格式：

```ts
type LayoutEditorMessage = {
  channel: 'layout_editor' | string;
  type: string;
  requestId?: string;
  ok?: boolean;
  error?: string;
  data?: any;
}
```

### 3.2 iframe -> 父页面（事件）

- `type: 'sdk_ready'`  
  `data: { version: string, channel: string }`
- `type: 'layout_changed'`  
  `data: { id: string, name: string }`

### 3.3 父页面 -> iframe（命令）

命令消息的 `type`：

- `export_layout`
- `import_layout`，`data: { json: string }`
- `list_layouts`
- `select_layout`，`data: { id: string }`
- `toggle_edit`

### 3.4 响应（iframe -> 父页面）

iframe 会回包：

- `type: 'response'`
- `requestId`：与请求一致
- `ok: true | false`
- `data`：成功时可选
- `error`：失败时可选

成功回包示例：

```json
{ "channel":"layout_editor", "type":"response", "requestId":"1", "ok":true, "data": { "layouts": [ { "id":"a", "name":"A" } ] } }
```

### 3.5 父页面 Promise 封装示例

```js
function sendLayoutEditor(iframe, type, data) {
  const requestId = crypto.randomUUID();
  const targetOrigin = 'https://your-host';

  return new Promise((resolve, reject) => {
    const onMsg = (e) => {
      if (e.source !== iframe.contentWindow) return;
      if (e.origin !== targetOrigin) return;
      const msg = e.data;
      if (!msg || msg.channel !== 'layout_editor') return;
      if (msg.type !== 'response' || msg.requestId !== requestId) return;
      window.removeEventListener('message', onMsg);
      if (msg.ok) resolve(msg.data);
      else reject(new Error(msg.error || 'unknown_error'));
    };
    window.addEventListener('message', onMsg);
    iframe.contentWindow.postMessage(
      { channel: 'layout_editor', type, requestId, data },
      targetOrigin
    );
  });
}

// 使用
// const layouts = await sendLayoutEditor(iframe, 'list_layouts');
// const exported = await sendLayoutEditor(iframe, 'export_layout'); // { json: '...' }
```

常用调用示例：

```js
const iframe = document.getElementById('layout-editor');

const { layouts } = await sendLayoutEditor(iframe, 'list_layouts');
await sendLayoutEditor(iframe, 'select_layout', { id: layouts[0].id });

const { json } = await sendLayoutEditor(iframe, 'export_layout');
await sendLayoutEditor(iframe, 'import_layout', { json });
```

## 4. Flutter 侧配置（安全建议）

`initWebInterop(...)` 支持配置：

- `targetOrigin`：SDK 向父窗口发送消息时使用的 `postMessage(targetOrigin)`
- `allowedOrigins`：SDK 接收消息时允许的 `event.origin` 白名单（支持 `'*'`）
- `channel`：多实例/多业务隔离的通道名（默认 `layout_editor`）

生产环境建议：

- `targetOrigin` 使用明确域名（不要用 `'*'`）
- `allowedOrigins` 仅包含可信父页面域名

## 5. 给 AI 的最小协议摘要（可直接当提示词）

```
你正在集成一个 iframe 内嵌的 Layout Editor。父页面与 iframe 用 postMessage 通信。

消息结构 LayoutEditorMessage：
- channel: string（固定使用 'layout_editor'）
- type: string
- requestId?: string
- ok?: boolean（仅 response）
- error?: string（仅 response 且 ok=false）
- data?: any

iframe -> parent 事件：
- {channel:'layout_editor', type:'sdk_ready', data:{version:string, channel:string}}
- {channel:'layout_editor', type:'layout_changed', data:{id:string, name:string}}

parent -> iframe 命令（必须带 requestId）：
- export_layout（回包 data:{json:string}）
- import_layout（data:{json:string}）
- list_layouts（回包 data:{layouts:Array<{id,name}>}）
- select_layout（data:{id:string}）
- toggle_edit

iframe -> parent 回包：
- {channel:'layout_editor', type:'response', requestId, ok:true, data?:...}
- {channel:'layout_editor', type:'response', requestId, ok:false, error:string}

安全要求：
- 父页面必须校验 event.source === iframe.contentWindow 且 event.origin === editorOrigin
- 发送 postMessage 时 targetOrigin 必须是 editorOrigin（不要用 '*')
```
