<template lang="html">
  <div v-bind:style="{ backgroundColor: '#F4F7DE'}">
    <sui-container text-align="center">
      <sui-divider hidden />
      <sui-container >
        <h1 is="sui-header">
          <sui-image src="kadena.png" />
          Crowdfunding
        </h1>
      </sui-container >
      <sui-header-subheader>Build a Project for Kadena!</sui-header-subheader>
    </sui-container>
    <sui-container text-align="center">
      <sui-divider hidden />
      <sui-button v-bind:style="{ backgroundColor: '#728F00'}" inverted @click.native="openPrjDialog()">Start a Campaign</sui-button>
    </sui-container>
    <div>
      <sui-modal v-model="startProjectDialog">
        <sui-modal-header>Describe Your Project</sui-modal-header>
        <sui-modal-content>
          <sui-form>
            <sui-form-field required>
              <label>Your Testnet Account on Chain 0</label>
              <input v-model="newProject.account" placeholder="Account Name" />
            </sui-form-field>
            <sui-form-field required>
              <label>Project Title</label>
              <input v-model="newProject.title" placeholder="Project Title" />
            </sui-form-field>
            <sui-form-field required>
              <label>Description</label>
              <textarea v-model="newProject.description" placeholder="Description" />
            </sui-form-field>
            <sui-form-field>
              <sui-form-field required>
                <label>Start Date(Fundraising Starts)</label>
                <input
                  v-model="newProject.startDate"
                  placeholder="Start Date"
                  type="datetime-local"
                  :min="new Date().toISOString().slice(0,16)"
                  :max="new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().slice(0,16)"
                  />
              </sui-form-field>
              <sui-form-field required>
                <label>Target Date(Fundraising Ends)</label>
                <input type="datetime-local" v-model="newProject.targetDate" placeholder="Target Date"
                  :min="new Date().toISOString().slice(0,16)"
                  :max="new Date(new Date().setFullYear(new Date().getFullYear() + 1)).toISOString().slice(0,16)"
                />
              </sui-form-field>
              <sui-form-field required>
                <label>Target Raise (in testnet KDA)</label>
                <input type="number" v-model="newProject.targetRaise" placeholder="Target Raise" />
              </sui-form-field>
            </sui-form-field>
          </sui-form>
        </sui-modal-content>
        <sui-modal-actions>
          <sui-button
          positive
          type="submit"
          @click="startProject()"
          >Submit</sui-button>
          <sui-button
            negative
            @click="cancelDialog()"
            newProject.isLoading = false
            >
            Cancel
          </sui-button>
        </sui-modal-actions>
      </sui-modal>
    </div>
    <div>
      <sui-modal v-model="reqKeyDialog">
        <sui-modal-header>Your Request Key is </sui-modal-header>
        <sui-modal-content>
          Request Key: {{requestKey}}<br/>
          Result: {{pollResult}}
        </sui-modal-content>
        <sui-modal-actions>
          <sui-button
            Positive
            @click="pollReqKey()"
            >
            Check Status
          </sui-button>
          <sui-button
            negative
            @click="closeReqKey()"
            >
            Close
          </sui-button>
        </sui-modal-actions>
      </sui-modal>
    </div>
    <div>
      <sui-modal v-model="fundProjectDialog">
        <sui-modal-header>Support {{projectToFund.title}}</sui-modal-header>
        <sui-modal-content>
          <sui-form>
            <sui-form-field>
              <label>Your Kadena Account</label>
              <input
                v-model="projectToFund.account"
                placeholder="Account" >
            </sui-form-field>
            <sui-form-field>
              <label>Amount (in testnet KDA)</label>
              <input
              type="number"
              v-model="projectToFund.amount"
              placeholder="Amount" >
            </sui-form-field>
          </sui-form>
        </sui-modal-content>
        <sui-modal-actions>
          <sui-button
          positive
          type="submit"
          @click="fundProject()"
          >Support</sui-button>
          <sui-button
            negative
            @click="fundProjectDialog=false"
            >
            Cancel
          </sui-button>
        </sui-modal-actions>
      </sui-modal>
    </div>
    <div>
      <sui-divider hidden />
      <sui-menu pointing inverted>
        <a
          is="sui-menu-item"
          v-for="item in menus"
          :active="isActive(item)"
          :key="item"
          :content="item"
          @click="select(item)"
        />
      </sui-menu>
    </div>
    <sui-divider hidden />
      <div>
        <sui-card-group :items-per-row="2">
           <sui-card  raised v-for="(project, index) in showing">
             <sui-card-content>
               <sui-statistic size="small" floated="right">
                 <sui-statistic-value>{{project.targetAmount}}</sui-statistic-value>
                 <sui-statistic-label>Target Raise</sui-statistic-label>
               </sui-statistic>
               <sui-statistic size="small" floated="right">
                 <sui-statistic-value>{{project.currentAmount}}</sui-statistic-value>
                 <sui-statistic-label>Current Raise</sui-statistic-label>
               </sui-statistic>
               <sui-label class="left floated" :color="stateMap[project.status].color">
                 {{ stateMap[project.status].text}}
               </sui-label>
               <sui-card-header>{{project.title}}</sui-card-header>
               <sui-card-meta>
                 <span>{{project.startDate.toISOString().slice(0,10) + " ~ " + project.targetDate.toISOString().slice(0,10)}}</span>
               </sui-card-meta>
               <sui-card-meta>
                 <span>Project Owner: {{project.owner}}</span>
               </sui-card-meta>
               <sui-card-description>
                 {{project.description}}
               </sui-card-description>
               <sui-progress
                 :color="stateMap[project.status].color"
                 :percent="(project.currentAmount>project.targetAmount) ? 100 : (project.currentAmount / project.targetAmount) * 100"
                 progress
               />
              <sui-button
                v-if="showing[index].status===2"
                @click="succeedCampaign(project.title, project.owner)">
                Process Funding
              </sui-button>
              <sui-button
                color="green"
                content="Support this Campaign"
                v-if="showing[index].status===0 && new Date(showing[index].targetDate)>new Date()"
                @click.native="openFundDialog(index)"/>
              <sui-button
                content="Learn More"
                v-if="showing[index].pacts===false &&  showing[index].status !== 4"
                @click="getPacts(index)"
                :loading="project.isLoading"/>
              <sui-button
                basic
                color="red"
                content="Close"
                v-if="showing[index].pacts===true"
                @click="closePacts(index)"
                :loading="project.isLoading"/>
             </sui-card-content>
             <sui-card-content extra v-if="showing[index].pacts===true">
              <sui-container>
                <sui-button
                  negative
                  content="Process Refund"
                  v-if="project.status===1 || project.status===3"
                  @click="cancelPacts(project.title)"/>
                <sui-button
                  negative
                  color="red"
                  v-if="showing[index].status===0 && new Date(showing[index].targetDate)>new Date()"
                  @click.native="cancelCampaign(project.title)">
                  Cancel this campaign
                </sui-button>
                <sui-button
                  negative
                  v-if="showing[index].status===0 && new Date(showing[index].targetDate)<new Date()"
                  @click.native="failCampaign(project.title)"
                  content="This campaign failed - refund"
                  />
                <sui-button
                  v-if="showing[index].status===0 && new Date(showing[index].targetDate)<new Date()"
                  @click.native="proceedCampaign(project.title, project.owner)"
                  content="This campaign succeeded - process" />
                <label>Supporters: </label>
                 <a is="sui-label"  v-for="(pact, index) in showing[index].pactsList" :key="index" >
                  {{pact.issuer}}
                 </a>
              </sui-container>
            </sui-card-content>
          </sui-card>
       </sui-card-group>
      </div>
    </div>
</template>

<script>
import Pact from './pact-lang-api.js';
import uuid from 'uuidv4';
import ks from './ks.js';

export default {
  name: 'App',
  data() {
    return {
      startProjectDialog: false,
      fundProjectDialog:false,
      reqKeyDialog: false,
      active: 'All',
      menus: ['Started', 'Canceled', 'Succeeded', 'Expired', 'Upcoming', 'All'],
      activeMenu: 'All',
      stateMap: [
        { color: 'blue', text: 'Started' },
        { color: 'red', text: 'Canceled' },
        { color: 'green', text: 'Completed' },
        { color: 'orange', text: 'Expired' },
        { color: 'yellow', text: 'Upcoming' }
      ],
      requestKey: [],
      pollResult:{},
      pacts:[],
      projectData: [],
      newProject: { isLoading: false },
      APIHost : "https://us1.testnet.chainweb.com/chainweb/0.0/testnet02/chain/0/pact",
      showing: [],
      projectToFund:{}
    };
  },
  mounted() {
    this.getProjects();
  },
  methods: {
    isActive(name) {
      return this.active === name;
    },
    select(name) {
      this.activeMenu = name;
      if (this.activeMenu==="All") {
        this.showing=this.projectData.sort((a,b)=>{
          return a.status-b.status;
        });
        this.active=name;
      }
      else {
        this.showing = this.projectData.filter(prj => prj.status ===this.menus.indexOf(this.activeMenu))
        .sort((a,b)=>{
          return a.status-b.status;
      });
        this.active=name;
      }
    },
    getProjects() {
      const cmd= {
        pactCode: Pact.lang.mkExp("crowdfund-campaign.read-campaigns"),
        keyPairs: Pact.crypto.genKeyPair()
      }
      Pact.fetch.local(cmd, this.APIHost)
      .then((res) => {
        return res.data
      })
      .then((projects) => {
         this.projectData = projects.map(prj =>{
           return {
             title:prj.title,
             description:prj.description,
             status: prj.status.int=== 0 && new Date(prj["start-date"]["time"]) > new Date() ? 4 : prj.status.int,
             currentAmount: prj["current-raise"],
             targetAmount: prj["target-raise"],
             targetDate: this.convertUTCtoEST(prj["target-date"]["time"], 0),
             startDate: this.convertUTCtoEST(prj["start-date"]["time"], 0),
             owner: prj.ownerAccount,
             dialog:false,
             pacts: false }
         }).sort((a,b)=>{
           return a.status-b.status;
         })
         this.showing = projects.map(prj =>{
           return {
             title:prj.title,
             description:prj.description,
             status: prj.status.int===0 && new Date(prj["start-date"]["time"]) > new Date() ? 4 : prj.status.int,
             currentAmount: prj["current-raise"],
             targetAmount: prj["target-raise"],
             targetDate: this.convertUTCtoEST(prj["target-date"]["time"], 0),
             startDate: this.convertUTCtoEST(prj["start-date"]["time"], 0),
             owner: prj.ownerAccount,
             dialog:false,
             pacts: false,
             pactsList: [] }
         }).sort((a,b)=>{
           return a.status-b.status;
         })
       })
    },
    getPacts(index){
      this.showing[index].pacts=true;
      const project = this.showing[index]
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project.title)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      Pact.fetch.local(cmd, this.APIHost)
      .then((res) => {
        return res.data
      })
      .then((pacts) => {
         this.showing[index].pactsList = pacts.filter(p=>p.status.int!==1).map(p =>{
           return {campaign:p["campaign-title"], issuer:p.fundOwner, status:p.status.int, pactId: p["pact-id"]};
         });
       });
    },
    convertToUTC(date){
      date = new Date(date)
      return JSON.stringify(new Date(date.getTime() + date.getTimezoneOffset() * 60).toISOString().replace(/\.[0-9]{3}/, ''))
    },
    convertUTCtoEST(date, hours){
      date = new Date(date)
      return new Date(date.getTime() - date.getTimezoneOffset() * 60)
    },
    openPrjDialog(){
      this.newProject = {};
      this.startProjectDialog = true;
    },
    closePacts(index){
      this.showing[index].pacts=false;
      this.pacts=[];
    },
    closeReqKey(){
      this.pollResult = {};
      this.requestKey = [];
      this.reqKeyDialog = false;
    },
    async startProject() {
      const pactCode = `(crowdfund-campaign.create-campaign "${this.newProject.title}" "${this.newProject.description}" "${this.newProject.account}"
      ${this.newProject.targetRaise.indexOf('.') === -1
          ? `${this.newProject.targetRaise}.0`
          : this.newProject.targetRaise} (time ${this.convertToUTC(this.newProject.startDate)}) (time ${this.convertToUTC(this.newProject.targetDate)})))`;
      const cmd = await Pact.wallet.sign({
        pactCode: pactCode,
        caps: [
          Pact.lang.mkCap("Account Guard", "Check owner guard", `user.crowdfund-campaign.ACCT_GUARD`, [this.newProject.account])],
        chainId: "0"});
      const reqKey = await Pact.wallet.sendSigned(cmd, this.APIHost);
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
      this.startProjectDialog = false;
    },
    openFundDialog(index){
      this.fundProjectDialog=true;
      this.showing[index].dialog=true;
      this.projectToFund = this.showing[index];
    },
    cancelDialog(){
      this.newProject = {};
      this.startProjectDialog = false;
    },
    async fundProject() {
      let id = uuid();
      const prj = this.projectToFund;
      const pactCode = `(crowdfund-campaign.fund-campaign "${prj.account}" "${prj.title}" ${prj.amount.indexOf('.') === -1
          ? `${prj.amount}.0`
          : prj.amount} "${id}")`;
      const cmd = await Pact.wallet.sign({
        pactCode: pactCode,
        caps: [
          Pact.lang.mkCap("Account Guard", "Check owner guard", `user.crowdfund-campaign.ACCT_GUARD`, [prj.account]),
          Pact.lang.mkCap("Transfer to Escrow", "escrow account with pactId", "coin.TRANSFER", [prj.account, id, Number(prj.amount)])
        ],
        chainId: "0"});
      const reqKey = await Pact.wallet.sendSigned(cmd, this.APIHost)
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
      this.fundProjectDialog=false
    },
    async cancelPacts(project) {
      let pacts=[];
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      const res = await Pact.fetch.local(cmd, this.APIHost);
      pacts = res.data.filter(p=>p.status.int!==1);
      const contCmd = (pact) => {
        console.log(pact)
        return {
          networkId: "testnet02",
          keyPairs: [{...ks, clist: [{name: "coin.GAS", args: []}]},{...Pact.crypto.genKeyPair(), clist: [{name: "coin.TRANSFER", args: [pact.escrow, pact.fundOwner, pact.amount]}]}],
          pactId: pact["pact-id"],
          step: 0,
          rollback: true,
          meta: Pact.lang.mkMeta("heekyun-testnet", "0", 0.0000001, 100000, Math.round((new Date).getTime()/1000)-15, 28800)
        }
      }
      const contCmdArray = pacts.map(pact => contCmd(pact))
      const reqKey = await Pact.fetch.cont(contCmdArray, this.APIHost)
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
    },
    async cancelCampaign(title){
      const pactCode = `(crowdfund-campaign.cancel-campaign "${title}")`;
      const cmd = await Pact.wallet.sign({pactCode: pactCode, caps: [
        Pact.lang.mkCap("Campaign Guard", "Check campaign owner's guard", "user.crowdfund-campaign.CAMPAIGN_GUARD", [title]),
      ], chainId: "0"});
      const reqKey = await Pact.wallet.sendSigned(cmd, this.APIHost);
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
    },
    async failCampaign(title){
      const pactCode = `(crowdfund-campaign.fail-campaign "${title}")`;
      const cmd = await Pact.wallet.sign({
        pactCode: pactCode,
        keyPairs: ks,
        meta: Pact.lang.mkMeta("heekyun-testnet", "0", 0.000001, 10000, Math.round((new Date).getTime()/1000)-15, 28800)
      });
      const reqKey = await Pact.fetch.send(cmd, this.APIHost)
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
    },
    async proceedCampaign(title){
      const pactCode = `(crowdfund-campaign.succeed-campaign "${title}")`;
      const cmd= {
        networkId: "testnet02",
        pactCode: pactCode,
        keyPairs: ks,
        meta: Pact.lang.mkMeta("heekyun-testnet", "0", 0.000001, 10000, Math.round((new Date).getTime()/1000)-15, 28800)
      }
      const reqKey = await Pact.fetch.send(cmd, this.APIHost)
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
    },
    async pollReqKey(){
      this.pollResult = await Pact.fetch.poll({requestKeys: this.requestKey}, this.APIHost)
    },
    async succeedCampaign(project, owner){
    let pacts=[];
      const cmd= {
        pactCode: Pact.lang.mkExp(`crowdfund-campaign.fetch-pacts ${JSON.stringify(project)}`),
        keyPairs: Pact.crypto.genKeyPair()
      }
      const res = await Pact.fetch.local(cmd, this.APIHost);
      pacts = res.data.filter(p=>p.status.int!==1);
      const contCmd = (pact) => {
        return {
          networkId: "testnet02",
          keyPairs: [{...ks, clist: [{name: "coin.GAS", args: []}]}, {...Pact.crypto.genKeyPair(), clist: [{name: "coin.TRANSFER", args: [pact.escrow, owner, pact.amount]}]}],
          pactId: pact["pact-id"],
          step: 1,
          rollback: false,
          meta: Pact.lang.mkMeta("heekyun-testnet", "0", 0.0000001, 100000, Math.round((new Date).getTime()/1000)-15, 28800)
        }
      }
      const contCmdArray = pacts.map(pact => contCmd(pact))
      const reqKey = await Pact.fetch.cont(contCmdArray, this.APIHost)
      this.requestKey=reqKey.requestKeys;
      this.reqKeyDialog=true;
    }
  }


};
</script>
