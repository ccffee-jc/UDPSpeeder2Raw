new Vue({
  el: '#app',
  data: {
    config: {
      global: {
        remote_host: '',
        password: ''
      },
      groups: []
    },
    groups: [],
    showGlobalConfig: false,
    showCreateGroup: false,
    showEditGroup: false,
    showDeleteConfirm: false,
    globalConfig: {
      remote_host: '',
      password: ''
    },
    newGroup: {
      name: '',
      fec_config: '1:1,2:1,10:3,20:5',
      mode: 0,
      timeout: 4,
      queue: 20,
      interval: 5,
      udp2raw_extra: '--fix-gro'
    },
    editIndex: -1,
    deleteIndex: -1
  },
  
  mounted() {
    this.loadConfig();
  },
  
  methods: {
    async loadConfig() {
      try {
        const response = await fetch('/api/config');
        const data = await response.json();
        this.config = data;
        this.groups = data.groups;
      } catch (error) {
        console.error('加载配置失败:', error);
        alert('加载配置失败');
      }
    },
    
    async updateGlobalConfig() {
      try {
        const response = await fetch('/api/config/global', {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.globalConfig)
        });
        
        if (response.ok) {
          this.config.global = { ...this.globalConfig };
          this.showGlobalConfig = false;
          alert('全局配置已更新');
        } else {
          throw new Error('更新失败');
        }
      } catch (error) {
        console.error('更新全局配置失败:', error);
        alert('更新全局配置失败');
      }
    },
    
    async createGroup() {
      try {
        const response = await fetch('/api/groups', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.newGroup)
        });
        
        if (response.ok) {
          const newGroup = await response.json();
          this.groups.push(newGroup);
          this.showCreateGroup = false;
          this.newGroup = this.getDefaultGroup();
          alert('节点创建成功');
        } else {
          throw new Error('创建失败');
        }
      } catch (error) {
        console.error('创建节点失败:', error);
        alert('创建节点失败');
      }
    },
    
    async updateGroup() {
      try {
        const response = await fetch(`/api/groups/${this.editIndex}`, {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.newGroup)
        });
        
        if (response.ok) {
          const updatedGroup = await response.json();
          this.groups.splice(this.editIndex, 1, updatedGroup);
          this.showEditGroup = false;
          this.editIndex = -1;
          alert('节点更新成功');
        } else {
          throw new Error('更新失败');
        }
      } catch (error) {
        console.error('更新节点失败:', error);
        alert('更新节点失败');
      }
    },
    
    async deleteGroup() {
      try {
        const response = await fetch(`/api/groups/${this.deleteIndex}`, {
          method: 'DELETE'
        });
        
        if (response.ok) {
          this.groups.splice(this.deleteIndex, 1);
          this.showDeleteConfirm = false;
          this.deleteIndex = -1;
          alert('节点删除成功');
        } else {
          throw new Error('删除失败');
        }
      } catch (error) {
        console.error('删除节点失败:', error);
        alert('删除节点失败');
      }
    },
    
    async exportGroup(index) {
      try {
        const response = await fetch(`/api/groups/${index}/export`, {
          method: 'POST'
        });
        
        if (response.ok) {
          const blob = await response.blob();
          const url = window.URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.style.display = 'none';
          a.href = url;
          a.download = `${this.groups[index].name}_client.zip`;
          document.body.appendChild(a);
          a.click();
          window.URL.revokeObjectURL(url);
          document.body.removeChild(a);
        } else {
          throw new Error('导出失败');
        }
      } catch (error) {
        console.error('导出配置失败:', error);
        alert('导出配置失败');
      }
    },
    
    editGroup(index) {
      this.editIndex = index;
      this.newGroup = { ...this.groups[index] };
      this.showEditGroup = true;
    },
    
    confirmDelete(index) {
      this.deleteIndex = index;
      this.showDeleteConfirm = true;
    },
    
    closeGroupModal() {
      this.showCreateGroup = false;
      this.showEditGroup = false;
      this.editIndex = -1;
      this.newGroup = this.getDefaultGroup();
    },
    
    getDefaultGroup() {
      return {
        name: '',
        fec_config: '1:1,2:1,10:3,20:5',
        mode: 0,
        timeout: 4,
        queue: 20,
        interval: 5,
        udp2raw_extra: '--fix-gro'
      };
    }
  },
  
  watch: {
    showGlobalConfig(show) {
      if (show) {
        this.globalConfig = { ...this.config.global };
      }
    }
  }
});
