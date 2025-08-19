'use strict';

const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const archiver = require('archiver');

const app = express();
const PORT = process.env.PORT || 3000;
const CONFIG_FILE = '/app/config.json';

// 中间件
app.use(express.json());
app.use(express.static(path.join(__dirname, 'www')));

// 读取配置文件
function readConfig() {
  try {
    if (!fs.existsSync(CONFIG_FILE)) {
      // 如果配置文件不存在，创建默认配置
      const defaultConfig = {
        global: {
          remote_host: "1.2.3.4",
          password: "password123"
        },
        groups: []
      };
      fs.writeFileSync(CONFIG_FILE, JSON.stringify(defaultConfig, null, 2));
      return defaultConfig;
    }
    return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch (error) {
    console.error('读取配置文件失败:', error);
    throw error;
  }
}

// 写入配置文件
function writeConfig(config) {
  try {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
  } catch (error) {
    console.error('写入配置文件失败:', error);
    throw error;
  }
}

// 生成下一个可用端口
function getNextAvailablePorts(config) {
  const usedPorts = new Set();
  
  config.groups.forEach(group => {
    usedPorts.add(group.speeder_port);
    usedPorts.add(group.udp2raw_port);
  });

  let speederPort = 10001;
  let udp2rawPort = 10002;

  // 找到第一个可用的端口对
  while (usedPorts.has(speederPort) || usedPorts.has(udp2rawPort)) {
    speederPort += 10;
    udp2rawPort += 10;
  }

  return { speederPort, udp2rawPort };
}

// API路由
app.get('/api/config', (req, res) => {
  try {
    const config = readConfig();
    res.json(config);
  } catch (error) {
    res.status(500).json({ error: '读取配置失败' });
  }
});

app.put('/api/config/global', (req, res) => {
  try {
    const config = readConfig();
    config.global = req.body;
    writeConfig(config);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: '更新全局配置失败' });
  }
});

app.get('/api/groups', (req, res) => {
  try {
    const config = readConfig();
    res.json(config.groups);
  } catch (error) {
    res.status(500).json({ error: '读取节点列表失败' });
  }
});

app.post('/api/groups', (req, res) => {
  try {
    const config = readConfig();
    const { speederPort, udp2rawPort } = getNextAvailablePorts(config);
    
    const newGroup = {
      name: req.body.name,
      speeder_port: speederPort,
      udp2raw_port: udp2rawPort,
      fec_config: req.body.fec_config || "1:1,2:1,10:3,20:5",
      mode: req.body.mode || 0,
      timeout: req.body.timeout || 4,
      queue: req.body.queue || 20,
      interval: req.body.interval || 5,
      udp2raw_extra: req.body.udp2raw_extra || "--fix-gro"
    };

    config.groups.push(newGroup);
    writeConfig(config);
    
    // 重启服务
    exec('cd /app && ./restart.sh', (error) => {
      if (error) {
        console.error('重启服务失败:', error);
      }
    });

    res.json(newGroup);
  } catch (error) {
    res.status(500).json({ error: '创建节点失败' });
  }
});

app.put('/api/groups/:index', (req, res) => {
  try {
    const config = readConfig();
    const index = parseInt(req.params.index);
    
    if (index < 0 || index >= config.groups.length) {
      return res.status(404).json({ error: '节点不存在' });
    }

    // 保持端口不变
    const updatedGroup = {
      ...req.body,
      speeder_port: config.groups[index].speeder_port,
      udp2raw_port: config.groups[index].udp2raw_port
    };

    config.groups[index] = updatedGroup;
    writeConfig(config);
    
    // 重启服务
    exec('cd /app && ./restart.sh', (error) => {
      if (error) {
        console.error('重启服务失败:', error);
      }
    });

    res.json(updatedGroup);
  } catch (error) {
    res.status(500).json({ error: '更新节点失败' });
  }
});

app.delete('/api/groups/:index', (req, res) => {
  try {
    const config = readConfig();
    const index = parseInt(req.params.index);
    
    if (index < 0 || index >= config.groups.length) {
      return res.status(404).json({ error: '节点不存在' });
    }

    config.groups.splice(index, 1);
    writeConfig(config);
    
    // 重启服务
    exec('cd /app && ./restart.sh', (error) => {
      if (error) {
        console.error('重启服务失败:', error);
      }
    });

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: '删除节点失败' });
  }
});

app.post('/api/groups/:index/export', (req, res) => {
  try {
    const config = readConfig();
    const index = parseInt(req.params.index);
    
    if (index < 0 || index >= config.groups.length) {
      return res.status(404).json({ error: '节点不存在' });
    }

    const group = config.groups[index];
    const groupName = group.name;

    // 执行生成客户端配置的命令
    exec(`cd /app && ./generateClient.sh "${groupName}"`, (error, stdout, stderr) => {
      if (error) {
        console.error('生成客户端配置失败:', error);
        return res.status(500).json({ error: '生成客户端配置失败' });
      }

      // 检查生成的文件是否存在
      const clientOutDir = `/app/client_out/${groupName}`;
      if (!fs.existsSync(clientOutDir)) {
        return res.status(500).json({ error: '客户端配置文件不存在' });
      }

      // 创建ZIP文件
      const archive = archiver('zip', {
        zlib: { level: 9 }
      });

      res.attachment(`${groupName}_client.zip`);
      archive.pipe(res);

      archive.directory(clientOutDir, false);
      archive.finalize();
    });
  } catch (error) {
    res.status(500).json({ error: '导出配置失败' });
  }
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`UDPSpeeder2Raw Web Interface 运行在端口 ${PORT}`);
  
  // 启动映射服务器
  exec('cd /app && ./start_mapping_server.sh', (error, stdout, stderr) => {
    if (error) {
      console.error('启动映射服务器失败:', error);
    } else {
      console.log('映射服务器已启动');
    }
  });
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('正在关闭服务器...');
  exec('cd /app && ./stop_mapping_server.sh', () => {
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('正在关闭服务器...');
  exec('cd /app && ./stop_mapping_server.sh', () => {
    process.exit(0);
  });
});
